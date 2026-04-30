# Lot TSX-7 — TSX Role Mapping UX / Visual Assignment Builder V0

## 1. Verdict

V2 TSX-7 implémenté.

Le workflow TSX conserve sa chaîne technique existante, mais le mapping rôle Surface -> animation TSX n'est plus piloté par des champs texte bruts. L'utilisateur dispose maintenant d'un builder visuel groupé par rôles, avec picker d'animations, aperçu ou fallback, statut assigné/vide, source Manuel/Mistral, confiance Mistral et résumé des animations utilisées/restantes.

Aucun preset n'est créé automatiquement. Aucun rôle n'est deviné sans validation humaine. Aucun code gameplay/runtime/battle n'a été modifié dans ce lot.

## 2. Audit Initial

### Commandes d'audit exécutées

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "TiledTsxSurfacePresetDraft|roleAnimationIds|animation id sélectionnée|Créer le preset|Suggestions Mistral|Appliquer les suggestions|SurfaceVariantRole|TiledTsxAnimationBrowser|TiledTsxSurfaceAnimationPreview|tech-animations-tile" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
```

### Réponses d'audit

1. Le formulaire actuel `role -> animationId` était rendu dans `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart`, dans `_TiledTsxSurfacePresetBuilderPanel`.
2. Il utilisait des `TextEditingController` par rôle et un widget `_RoleAnimationField`, donc l'utilisateur devait manipuler des ids bruts comme `tech-animations-tile-99`.
3. Les suggestions Mistral étaient affichées dans `_TiledTsxMistralGroupingPanel` sous forme de lignes textuelles via `_TiledTsxMistralSuggestionRow`.
4. Une suggestion acceptée appelait `_applyMistralSuggestion`, qui remplissait directement le contrôleur texte du rôle.
5. Une preview réutilisable existait partiellement dans le browser TSX, mais elle était localisée autour de la preview d'animation et non dans un builder de rôles.
6. Les labels de rôles existaient via `SurfaceStudioRoleLabels.labelForRole`, mais pas de composant visuel dédié au mapping TSX.
7. Les groupes du schema panel n'étaient pas exposés comme composant réutilisable. TSX-7 recrée les groupes UX demandés sans modifier `map_core`.
8. Une animation peut être affichée sans rôle en lisant ses frames `ProjectSurfaceAnimation` et le `SurfaceAtlasTileRef` de sa première frame.
9. Les ids bruts restent visibles comme information secondaire, mais la sélection ne se fait plus par saisie manuelle.
10. Les tests vérifient les slots par rôle, le picker, la preview/fallback et l'absence de l'ancien champ texte brut.

### État initial important

Le worktree contenait déjà des changements hors TSX-7 avant ce lot, notamment TSX-6/6-bis et tall grass : `tiled_tsx_workspace.dart`, `surface_studio_panel.dart`, `MainFlutterWindow.swift`, `surface_studio_panel_test.dart`, `tiled_tsx_transparent_color.dart`, `tall_grass_tsx_asset_importer.dart` et leurs tests. TSX-7 n'a pas cherché à les nettoyer ni à les réécrire.

## 3. Problème UX Constaté

L'UI précédente exposait des champs texte noirs avec des valeurs comme `tech-animations-tile-3235`. C'était techniquement correct, mais inutilisable pour un flux no-code : l'utilisateur voyait un id, pas le rôle, pas l'animation, pas son aperçu, pas sa provenance, et pas le degré de complétude de la surface.

TSX-7 traite ce problème côté authoring : le draft reste explicite, mais la manipulation devient visuelle.

## 4. Nouveau Builder Visuel Role -> Animation

Nouveau fichier : `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart`.

Le composant `TiledTsxRoleMappingBuilder` affiche les rôles par groupes :

- Surface principale : Plein(center), Horizontal, Vertical.
- Bords : Bord haut, Bord droit, Bord bas, Bord gauche.
- Coins externes.
- Coins internes.
- Jonctions : tés et croix.

Chaque slot affiche :

- label français ;
- nom technique discret ;
- explication courte ;
- animation assignée ou `Non assigné` ;
- preview ou fallback ;
- nombre de frames et durée ;
- base tile ;
- source `Manuel` ou `Mistral` ;
- confiance si la source est Mistral ;
- boutons `Choisir une animation` / `Changer` et `Clear`.

## 5. Picker Animation

Le mapping ne dépend plus d'un champ texte par rôle.

Le bouton `Choisir une animation` ouvre un picker visuel avec :

- recherche ;
- animation id visible ;
- frame count ;
- base tile ;
- preview ou fallback ;
- sélection par clic.

Les ids restent visibles pour les utilisateurs avancés, mais ils ne sont plus le mode principal de saisie.

## 6. Review Mistral

La review Mistral affiche maintenant une carte visuelle par suggestion :

- rôle français ;
- animation proposée ;
- preview ou fallback ;
- confiance ;
- evidence ids ;
- raison ;
- boutons accepter/rejeter.

Les warnings dupliqués sont groupés. Par exemple, plusieurs warnings `Rôle Mistral dupliqué rejeté : isolated.` deviennent un encart lisible :

```text
Suggestions ignorées
4 suggestions ont été ignorées car elles proposaient déjà Plein(center).
```

Le thinking Mistral n'est pas affiché par ce lot et le parsing robuste existant reste inchangé.

## 7. Preview / Fallback

`TiledTsxAnimationTilePreview` est exposé depuis le nouveau builder pour permettre :

- aperçu dans les slots de rôles ;
- aperçu dans le picker ;
- aperçu dans les cartes de suggestion Mistral.

Si les bytes d'image atlas sont indisponibles, l'UI affiche `Aperçu indisponible` plutôt qu'un espace vide ou un id brut.

Le builder affiche aussi un résumé global :

- `Plein(center) obligatoire` si isolated manque ;
- preview partielle active si isolated est présent ;
- nombre de rôles utilisés et manquants.

## 8. Draft et Création de Preset

La source de vérité reste `TiledTsxSurfacePresetDraft.roleAnimationIds`.

Les interactions font uniquement :

```text
choisir animation -> roleAnimationIds[role] = animationId
clear rôle -> remove(role)
accepter suggestion -> roleAnimationIds[role] = suggestion.animationId
```

Créer le preset reste une action explicite via le bouton `Créer le preset`. Aucun preset n'est créé par sélection, import ou Mistral.

## 9. Tests

### Tests ciblés TSX-7

#### tsx7_role_mapping_builder.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
00:00 +0: shows visual role slots and maps roles through a picker
00:00 +1: All tests passed!
```

#### tsx7_mistral_review_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
00:00 +0: Mistral review shows visual suggestions and grouped duplicates
00:00 +1: All tests passed!
```

#### tsx7_surface_preset_builder_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
00:00 +0: creates a preset from selected TSX animations only after explicit role mapping
00:01 +1: All tests passed!
```


### Régressions TSX

#### tsx7_regression_import_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
00:00 +0: TiledTsxWorkspace import UI loads a TSX, shows summary, imports atlas and animations
00:00 +1: TiledTsxWorkspace import UI blocks import when no matching tileset is available
00:00 +2: TiledTsxWorkspace import UI shows parser errors for invalid TSX
00:01 +3: TiledTsxWorkspace import UI blocks TSX without animations
00:01 +4: TiledTsxWorkspace import UI reports duplicate atlas id without mutating the catalog
00:01 +5: All tests passed!
```

#### tsx7_regression_animation_browser.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
00:00 +0: TiledTsxAnimationBrowser models builds browser items from the 242 imported Pokemon SDK animations
00:00 +1: TiledTsxAnimationBrowser models filters by animation id, display name, and base tile id
00:00 +2: TiledTsxAnimationBrowser widget selects and clears animations without mutating the catalog
00:00 +3: TiledTsxAnimationBrowser widget searches by tile id in the browser UI
00:01 +4: TiledTsxAnimationBrowser widget shows imported TSX frame details for tile 99
00:01 +5: TiledTsxSurfaceAnimationPreview steps through explicit ProjectSurfaceAnimation frames
00:01 +6: TiledTsxSurfaceAnimationPreview lists frames when atlas image bytes are unavailable
00:01 +7: All tests passed!
```

#### tsx7_regression_mistral_grouping_ui.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
00:00 +0: Mistral grouping button requires selection and configured key
00:00 +1: Mistral grouping shows missing key message
00:00 +2: Mistral grouping requires confirmation, shows progress, then fills draft only after accept
00:01 +3: All tests passed!
```

#### tsx7_regression_surface_preset_builder.log

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart
00:00 +0: TiledTsxSurfacePresetDraft validates and builds a preset from an explicit isolated mapping
00:00 +1: TiledTsxSurfacePresetDraft rejects duplicate preset ids
00:00 +2: TiledTsxSurfacePresetDraft requires isolated and known animation ids
00:00 +3: TiledTsxSurfacePresetDraft reports draft identity errors
00:00 +4: TiledTsxSurfacePresetDraft builds a preset from the real Pokemon SDK TSX import output
00:00 +5: All tests passed!
```


### Tous les tests Surface Studio

Commande exacte :

```bash
cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```

Ligne finale exacte :

```text
00:22 +423: All tests passed!
```

## 10. Analyze

Commande exacte :

```bash
cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart
```

Sortie complète :

```text
Analyzing 2 items...                                            
No issues found! (ran in 1.4s)
```

## 11. Non-objectifs Confirmés

- Pas de changement `map_core`.
- Pas de changement `map_gameplay`.
- Pas de changement `map_runtime`.
- Pas de changement `map_battle`.
- Pas de gameplay ajouté.
- Pas de `ProjectSurfacePreset` automatique.
- Pas de rôle deviné sans review humaine.
- Pas de PixelLab.
- Pas de MCP.
- Pas de génération d'image.
- Pas de nouvelle clé API.
- Pas de sauvegarde disque automatique.

## 12. Limites Restantes

- La preview globale de surface reste un résumé V0 ; elle ne compose pas encore une vraie grille autotile complète depuis tous les rôles TSX.
- Le picker est inline et simple ; il fonctionne, mais TSX-8 pourra améliorer le grouping visuel, masquer les animations déjà utilisées et proposer des packs candidats.
- Les previews affichent la première frame dans les slots. Un rendu animé complet par slot pourra venir ensuite si nécessaire.
- QA interactive macOS complète non exécutée dans ce lot ; la validation réalisée ici est automatisée Flutter/analyze.

## 13. Roadmap Suivante

TSX-8 — TSX Region / Grouping UX V0 :

- grouper visuellement les animations ;
- masquer les animations déjà utilisées ;
- afficher des packs candidats ;
- améliorer le workflow avant création du preset.

Puis TSX-9 — Paginated Mistral animation contact sheets si l'assistance IA sur grands ensembles reste utile.

## 14. Fichiers Créés / Modifiés par TSX-7

### Créés

- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart`

### Modifiés

- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart`

### Changements préexistants hors TSX-7 toujours présents

- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/macos/Runner/MainFlutterWindow.swift`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart`
- `packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart`
- `packages/map_editor/test/surface_studio/tall_grass_tsx_asset_importer_test.dart`
- `packages/map_editor/test/surface_studio/tiled_tsx_transparent_color_test.dart`

## 15. Contenu Complet des Fichiers TSX-7

### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show BoxDecoration, CustomPaint, InkWell;
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../surface_studio_mapping_suggestion_models.dart';
import '../surface_studio_vertical_atlas_role_mapping.dart';
import 'tiled_tsx_animation_browser_models.dart';

const Color _tsxRoleAccent = Color(0xFF2DD4BF);

enum TiledTsxRoleAssignmentSource {
  manual,
  mistral,
}

final class TiledTsxRoleAssignmentMeta {
  const TiledTsxRoleAssignmentMeta({
    required this.source,
    this.confidence,
  });

  final TiledTsxRoleAssignmentSource source;
  final SurfaceStudioMappingSuggestionConfidence? confidence;
}

class TiledTsxRoleMappingBuilder extends StatefulWidget {
  const TiledTsxRoleMappingBuilder({
    super.key,
    required this.atlas,
    required this.animations,
    required this.selectedAnimationIds,
    required this.roleAnimationIds,
    required this.roleSources,
    required this.onChanged,
    this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Set<String> selectedAnimationIds;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final Uint8List? atlasImageBytes;
  final ValueChanged<Map<SurfaceVariantRole, String>> onChanged;

  @override
  State<TiledTsxRoleMappingBuilder> createState() =>
      _TiledTsxRoleMappingBuilderState();
}

class _TiledTsxRoleMappingBuilderState
    extends State<TiledTsxRoleMappingBuilder> {
  final TextEditingController _query = TextEditingController();
  SurfaceVariantRole? _pickerRole;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final selectedAnimations = _selectedAnimations();
    final usedIds = widget.roleAnimationIds.values
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final remainingCount =
        widget.selectedAnimationIds.where((id) => !usedIds.contains(id)).length;
    return Container(
      key: const ValueKey('tiled_tsx_role_mapping_builder.root'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mapping visuel rôle → animation',
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choisissez une animation visuellement pour chaque rôle. Aucun ID n’a besoin d’être saisi à la main.',
              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _SummaryPill(
                  'Animations sélectionnées : ${widget.selectedAnimationIds.length}',
                ),
                _SummaryPill('Utilisées : ${usedIds.length}'),
                _SummaryPill('Restantes : $remainingCount'),
              ],
            ),
            const SizedBox(height: 10),
            _SurfacePreviewSummary(
              roleAnimationIds: widget.roleAnimationIds,
            ),
            if (_pickerRole != null) ...[
              const SizedBox(height: 8),
              _AnimationPicker(
                role: _pickerRole!,
                animations: selectedAnimations,
                query: _query,
                atlas: widget.atlas,
                atlasImageBytes: widget.atlasImageBytes,
                onQueryChanged: () => setState(() {}),
                onCancel: () => setState(() => _pickerRole = null),
                onSelected: (animationId) =>
                    _assignRole(_pickerRole!, animationId),
              ),
            ],
            const SizedBox(height: 12),
            for (final group in _roleGroups) ...[
              _RoleGroupHeader(title: group.title),
              const SizedBox(height: 6),
              for (final role in group.roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoleMappingSlot(
                    role: role,
                    animation: _animationForRole(role),
                    animationItem: _itemForRole(role),
                    source: widget.roleSources[role],
                    atlas: widget.atlas,
                    atlasImageBytes: widget.atlasImageBytes,
                    onPick: () {
                      setState(() {
                        _pickerRole = role;
                        _query.clear();
                      });
                    },
                    onClear: widget.roleAnimationIds.containsKey(role)
                        ? () => _clearRole(role)
                        : null,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<ProjectSurfaceAnimation> _selectedAnimations() {
    return widget.animations
        .where(
            (animation) => widget.selectedAnimationIds.contains(animation.id))
        .toList(growable: false);
  }

  ProjectSurfaceAnimation? _animationForRole(SurfaceVariantRole role) {
    final id = widget.roleAnimationIds[role];
    if (id == null) {
      return null;
    }
    for (final animation in widget.animations) {
      if (animation.id == id) {
        return animation;
      }
    }
    return null;
  }

  TiledTsxAnimationBrowserItem? _itemForRole(SurfaceVariantRole role) {
    final animation = _animationForRole(role);
    if (animation == null) {
      return null;
    }
    return buildTiledTsxAnimationBrowserItems(animations: [animation]).single;
  }

  void _assignRole(SurfaceVariantRole role, String animationId) {
    final next = Map<SurfaceVariantRole, String>.of(widget.roleAnimationIds);
    next[role] = animationId;
    widget.onChanged(Map<SurfaceVariantRole, String>.unmodifiable(next));
    setState(() => _pickerRole = null);
  }

  void _clearRole(SurfaceVariantRole role) {
    final next = Map<SurfaceVariantRole, String>.of(widget.roleAnimationIds)
      ..remove(role);
    widget.onChanged(Map<SurfaceVariantRole, String>.unmodifiable(next));
  }
}

class _SurfacePreviewSummary extends StatelessWidget {
  const _SurfacePreviewSummary({required this.roleAnimationIds});

  final Map<SurfaceVariantRole, String> roleAnimationIds;

  @override
  Widget build(BuildContext context) {
    final hasCenter = roleAnimationIds.containsKey(SurfaceVariantRole.isolated);
    final mappedCount = roleAnimationIds.length;
    final missingCount = standardSurfaceVariantRoleOrder.length - mappedCount;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasCenter
            ? _tsxRoleAccent.withValues(alpha: 0.10)
            : const Color(0xFFFACC15).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasCenter
              ? _tsxRoleAccent.withValues(alpha: 0.30)
              : const Color(0xFFFACC15).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        hasCenter
            ? 'Aperçu de la surface : preview partielle active. $mappedCount rôles utilisés, $missingCount rôles encore vides.'
            : 'Aperçu de la surface : Plein(center) obligatoire.',
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _AnimationPicker extends StatelessWidget {
  const _AnimationPicker({
    required this.role,
    required this.animations,
    required this.query,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onQueryChanged,
    required this.onCancel,
    required this.onSelected,
  });

  final SurfaceVariantRole role;
  final List<ProjectSurfaceAnimation> animations;
  final TextEditingController query;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onQueryChanged;
  final VoidCallback onCancel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final roleLabel = _labelForRole(role);
    final q = query.text.trim().toLowerCase();
    final visible = animations.where((animation) {
      if (q.isEmpty) {
        return true;
      }
      return animation.id.toLowerCase().contains(q) ||
          animation.name.toLowerCase().contains(q);
    }).toList(growable: false);
    return Container(
      key: ValueKey('tiled_tsx_role_mapping_builder.picker.${role.name}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _tsxRoleAccent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Choisir une animation pour $roleLabel',
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                onPressed: onCancel,
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    color: _tsxRoleAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            key: ValueKey('tiled_tsx_role_mapping_builder.search.${role.name}'),
            controller: query,
            placeholder: 'Rechercher une animation…',
            onChanged: (_) => onQueryChanged(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.editorIslandRim(context)
                    .withValues(alpha: 0.7),
              ),
            ),
            style: TextStyle(color: label, fontSize: 12),
            placeholderStyle: TextStyle(color: subtle, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            Text(
              'Aucune animation sélectionnée ne correspond.',
              style: TextStyle(color: subtle, fontSize: 11.5),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final animation in visible)
                      _AnimationPickerOption(
                        role: role,
                        animation: animation,
                        atlas: atlas,
                        atlasImageBytes: atlasImageBytes,
                        onSelected: () => onSelected(animation.id),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimationPickerOption extends StatelessWidget {
  const _AnimationPickerOption({
    required this.role,
    required this.animation,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onSelected,
  });

  final SurfaceVariantRole role;
  final ProjectSurfaceAnimation animation;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final item =
        buildTiledTsxAnimationBrowserItems(animations: [animation]).single;
    final subtle = EditorChrome.subtleLabel(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        key: ValueKey(
          'tiled_tsx_role_mapping_builder.option.${role.name}.${animation.id}',
        ),
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: TiledTsxAnimationTilePreview(
                  atlas: atlas,
                  animation: animation,
                  atlasImageBytes: atlasImageBytes,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animation.id,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_frameCountLabel(animation)} · base tile ${item.baseTileId}',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleMappingSlot extends StatelessWidget {
  const _RoleMappingSlot({
    required this.role,
    required this.animation,
    required this.animationItem,
    required this.source,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onPick,
    required this.onClear,
  });

  final SurfaceVariantRole role;
  final ProjectSurfaceAnimation? animation;
  final TiledTsxAnimationBrowserItem? animationItem;
  final TiledTsxRoleAssignmentMeta? source;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final assigned = animation != null;
    return Container(
      key: ValueKey('tiled_tsx_role_mapping_builder.slot.${role.name}'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: assigned
              ? _tsxRoleAccent.withValues(alpha: 0.34)
              : EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForRole(role),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: subtle, fontSize: 10.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _descriptionForRole(role),
                  style: TextStyle(color: subtle, fontSize: 10.8, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            height: 66,
            child: animation == null
                ? const _EmptyPreviewBox()
                : TiledTsxAnimationTilePreview(
                    atlas: atlas,
                    animation: animation!,
                    atlasImageBytes: atlasImageBytes,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animation?.id ?? 'Non assigné',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: assigned ? label : subtle,
                    fontSize: 12,
                    fontWeight: assigned ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                if (animation != null)
                  Text(
                    '${_frameCountLabel(animation!)} · ${animation!.totalDurationMs} ms',
                    style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
                  ),
                if (animation != null)
                  Text(
                    'base tile ${animationItem?.baseTileId ?? '—'}',
                    style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
                  ),
                if (source != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    source!.source == TiledTsxRoleAssignmentSource.mistral
                        ? 'Source : Mistral'
                        : 'Source : Manuel',
                    style: const TextStyle(
                      color: _tsxRoleAccent,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (source!.confidence != null)
                    Text(
                      'Confiance : ${source!.confidence!.name}',
                      style: const TextStyle(
                        color: _tsxRoleAccent,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    CupertinoButton(
                      key: ValueKey(
                        'tiled_tsx_role_mapping_builder.pick.${role.name}',
                      ),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      onPressed: onPick,
                      child: Text(
                        assigned ? 'Changer' : 'Choisir une animation',
                        style: const TextStyle(
                          color: _tsxRoleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (assigned)
                      CupertinoButton(
                        key: ValueKey(
                          'tiled_tsx_role_mapping_builder.clear.${role.name}',
                        ),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        onPressed: onClear,
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: _tsxRoleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TiledTsxAnimationTilePreview extends StatefulWidget {
  const TiledTsxAnimationTilePreview({
    super.key,
    required this.atlas,
    required this.animation,
    this.atlasImageBytes,
    this.compact = false,
  });

  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation animation;
  final Uint8List? atlasImageBytes;
  final bool compact;

  @override
  State<TiledTsxAnimationTilePreview> createState() =>
      _TiledTsxAnimationTilePreviewState();
}

class _TiledTsxAnimationTilePreviewState
    extends State<TiledTsxAnimationTilePreview> {
  ui.Image? _decoded;
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant TiledTsxAnimationTilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.atlasImageBytes != oldWidget.atlasImageBytes) {
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atlas = widget.atlas;
    final decoded = _decoded;
    final frames = widget.animation.timeline.frames;
    if (atlas == null ||
        decoded == null ||
        widget.atlasImageBytes == null ||
        frames.isEmpty) {
      return const _FallbackPreviewBox(text: 'Aperçu indisponible');
    }
    final frame = frames.first;
    final tileWidth = atlas.geometry.tileSize.width;
    final tileHeight = atlas.geometry.tileSize.height;
    final source = Rect.fromLTWH(
      (frame.tileRef.column * tileWidth).toDouble(),
      (frame.tileRef.row * tileHeight).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _TilePreviewPainter(image: decoded, source: source),
        child: const SizedBox.expand(),
      ),
    );
  }

  void _decodeImage() {
    final bytes = widget.atlasImageBytes;
    if (bytes == null || bytes.isEmpty) {
      _decodedBytes = null;
      _decoded?.dispose();
      _decoded = null;
      return;
    }
    if (identical(bytes, _decodedBytes)) {
      return;
    }
    _decodedBytes = bytes;
    ui.decodeImageFromList(bytes, (image) {
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _decoded?.dispose();
        _decoded = image;
      });
    });
  }
}

class _TilePreviewPainter extends CustomPainter {
  const _TilePreviewPainter({
    required this.image,
    required this.source,
  });

  final ui.Image image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    final destination = Offset.zero & size;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    canvas.drawImageRect(image, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant _TilePreviewPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.source != source;
  }
}

class _EmptyPreviewBox extends StatelessWidget {
  const _EmptyPreviewBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: const Center(
        child: Text(
          'Vide',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FallbackPreviewBox extends StatelessWidget {
  const _FallbackPreviewBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleGroupHeader extends StatelessWidget {
  const _RoleGroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tsxRoleAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tsxRoleAccent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: _tsxRoleAccent,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

final class _RoleGroup {
  const _RoleGroup({
    required this.title,
    required this.roles,
  });

  final String title;
  final List<SurfaceVariantRole> roles;
}

const _roleGroups = <_RoleGroup>[
  _RoleGroup(
    title: 'Surface principale',
    roles: [
      SurfaceVariantRole.isolated,
      SurfaceVariantRole.horizontal,
      SurfaceVariantRole.vertical,
    ],
  ),
  _RoleGroup(
    title: 'Bords',
    roles: [
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
    ],
  ),
  _RoleGroup(
    title: 'Coins externes',
    roles: [
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ],
  ),
  _RoleGroup(
    title: 'Coins internes',
    roles: [
      SurfaceVariantRole.innerCornerNW,
      SurfaceVariantRole.innerCornerNE,
      SurfaceVariantRole.innerCornerSW,
      SurfaceVariantRole.innerCornerSE,
    ],
  ),
  _RoleGroup(
    title: 'Jonctions',
    roles: [
      SurfaceVariantRole.teeNorth,
      SurfaceVariantRole.teeEast,
      SurfaceVariantRole.teeSouth,
      SurfaceVariantRole.teeWest,
      SurfaceVariantRole.cross,
    ],
  ),
];

String _labelForRole(SurfaceVariantRole role) {
  if (role == SurfaceVariantRole.isolated) {
    return 'Plein(center)';
  }
  return SurfaceStudioRoleLabels.labelForRole(role);
}

String _descriptionForRole(SurfaceVariantRole role) {
  return switch (role) {
    SurfaceVariantRole.isolated => 'Surface intérieure répétable.',
    SurfaceVariantRole.horizontal => 'Transition horizontale.',
    SurfaceVariantRole.vertical => 'Transition verticale.',
    SurfaceVariantRole.endNorth => 'Bord supérieur d’une surface.',
    SurfaceVariantRole.endEast => 'Bord droit d’une surface.',
    SurfaceVariantRole.endSouth => 'Bord inférieur d’une surface.',
    SurfaceVariantRole.endWest => 'Bord gauche d’une surface.',
    SurfaceVariantRole.cornerNW => 'Coin externe haut gauche.',
    SurfaceVariantRole.cornerNE => 'Coin externe haut droit.',
    SurfaceVariantRole.cornerSW => 'Coin externe bas gauche.',
    SurfaceVariantRole.cornerSE => 'Coin externe bas droit.',
    SurfaceVariantRole.innerCornerNW => 'Coin intérieur haut gauche.',
    SurfaceVariantRole.innerCornerNE => 'Coin intérieur haut droit.',
    SurfaceVariantRole.innerCornerSW => 'Coin intérieur bas gauche.',
    SurfaceVariantRole.innerCornerSE => 'Coin intérieur bas droit.',
    SurfaceVariantRole.teeNorth => 'Jonction en T vers le haut.',
    SurfaceVariantRole.teeEast => 'Jonction en T vers la droite.',
    SurfaceVariantRole.teeSouth => 'Jonction en T vers le bas.',
    SurfaceVariantRole.teeWest => 'Jonction en T vers la gauche.',
    SurfaceVariantRole.cross => 'Jonction en croix.',
  };
}

String _frameCountLabel(ProjectSurfaceAnimation animation) {
  final count = animation.frameCount;
  return count == 1 ? '1 frame' : '$count frames';
}
```

### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart

```dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../editor/application/editor_ai_settings.dart';
import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../surface_studio_vertical_atlas_preset_generator.dart';
import '../surface_studio_vertical_atlas_role_mapping.dart';
import 'tiled_tsx_animation_browser_models.dart';
import 'tiled_tsx_mistral_grouping_models.dart';
import 'tiled_tsx_mistral_grouping_suggester.dart';
import 'tiled_tsx_role_mapping_builder.dart';
import 'tiled_tsx_surface_preset_draft.dart';

const Color _tsxAccent = Color(0xFF2DD4BF);

class TiledTsxAnimationBrowser extends StatefulWidget {
  const TiledTsxAnimationBrowser({
    super.key,
    required this.atlas,
    required this.animations,
    this.atlasImageBytes,
    this.sourceLabel = 'TSX',
    this.onSelectionChanged,
    this.catalog,
    this.onSurfaceCatalogChanged,
    this.projectSettings,
    this.groupingSuggester,
  });

  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final String sourceLabel;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final ProjectSurfaceCatalog? catalog;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final ProjectSettings? projectSettings;
  final TiledTsxAnimationGroupingSuggester? groupingSuggester;

  @override
  State<TiledTsxAnimationBrowser> createState() =>
      _TiledTsxAnimationBrowserState();
}

class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
  final TextEditingController _query = TextEditingController();
  final TextEditingController _presetId = TextEditingController();
  final TextEditingController _presetName = TextEditingController();
  final TextEditingController _presetCategory = TextEditingController();
  final TextEditingController _presetSortOrder = TextEditingController();
  final Map<SurfaceVariantRole, TextEditingController> _roleControllers = {
    for (final role in standardSurfaceVariantRoleOrder)
      role: TextEditingController(),
  };
  Set<String> _selectedIds = const <String>{};
  String? _activeAnimationId;
  bool _onlySelected = false;
  bool _presetBuilderOpen = false;
  List<String> _presetBuilderErrors = const <String>[];
  List<String> _presetBuilderWarnings = const <String>[];
  String? _presetBuilderNote;
  bool _mistralConfirmOpen = false;
  bool _mistralPending = false;
  TiledTsxMistralGroupingResult? _mistralResult;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> _roleSources = {};

  @override
  void initState() {
    super.initState();
    _activeAnimationId =
        widget.animations.isEmpty ? null : widget.animations.first.id;
    _resetPresetDefaults();
  }

  @override
  void didUpdateWidget(covariant TiledTsxAnimationBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animations != oldWidget.animations) {
      final validIds =
          widget.animations.map((animation) => animation.id).toSet();
      final nextSelection =
          _selectedIds.where((id) => validIds.contains(id)).toSet();
      final activeStillValid =
          _activeAnimationId != null && validIds.contains(_activeAnimationId);
      setState(() {
        _selectedIds = nextSelection;
        _activeAnimationId = activeStillValid
            ? _activeAnimationId
            : widget.animations.isEmpty
                ? null
                : widget.animations.first.id;
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _presetId.dispose();
    _presetName.dispose();
    _presetCategory.dispose();
    _presetSortOrder.dispose();
    for (final controller in _roleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final items = buildTiledTsxAnimationBrowserItems(
      animations: widget.animations,
    );
    final visible = filterTiledTsxAnimationBrowserItems(
      items: items,
      filter: TiledTsxAnimationBrowserFilter(
        query: _query.text,
        onlySelected: _onlySelected,
      ),
      selectedAnimationIds: _selectedIds,
    );
    final active = _activeAnimation();
    final atlas = widget.atlas;
    final canCreateSurfaceFromSelection =
        _selectedIds.isNotEmpty && widget.onSurfaceCatalogChanged != null;
    final hasMistralKey = hasEditorMistralApiKey(widget.projectSettings);
    final canRunMistralGrouping =
        _selectedIds.isNotEmpty && hasMistralKey && !_mistralPending;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bodyHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? (constraints.maxHeight - 210).clamp(220.0, 520.0).toDouble()
                : 440.0;
        final animationBody = LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            final list = _AnimationList(
              items: visible,
              selectedIds: _selectedIds,
              activeAnimationId: _activeAnimationId,
              onToggleSelection: _toggleSelection,
              onActivate: _activateAnimation,
            );
            final preview = active == null
                ? _EmptyPreview(subtle: subtle)
                : TiledTsxSurfaceAnimationPreview(
                    atlas: atlas,
                    animation: active,
                    atlasImageBytes: widget.atlasImageBytes,
                  );
            if (!twoColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: list),
                  const SizedBox(height: 12),
                  SizedBox(height: 260, child: preview),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: list),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: preview),
              ],
            );
          },
        );
        return Container(
          key: const ValueKey('tiled_tsx_animation_browser.root'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: EditorChrome.elevatedPanelBackground(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EditorChrome.editorIslandRim(context)),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Animations TSX importées',
                  style: TextStyle(
                    color: label,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Animations lues depuis le fichier TSX. Les frames et durées viennent du fichier Tiled.',
                  style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill('${items.length} animations'),
                    _MetricPill(atlas == null ? '0 atlas' : '1 atlas'),
                    if (atlas != null)
                      _MetricPill(
                        '${atlas.geometry.tileSize.width}×${atlas.geometry.tileSize.height}',
                      ),
                    _MetricPill(widget.sourceLabel),
                  ],
                ),
                const SizedBox(height: 12),
                _SearchField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, toolbarConstraints) {
                    final selectionText = Text(
                      _selectionLabel(_selectedIds.length),
                      style: TextStyle(
                        color: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: [
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.create_surface'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed: canCreateSurfaceFromSelection
                              ? _openPresetBuilder
                              : null,
                          child: Text(
                            'Créer une surface depuis la sélection',
                            style: TextStyle(
                              color: canCreateSurfaceFromSelection
                                  ? _tsxAccent
                                  : subtle,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.mistral_grouping'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed: canRunMistralGrouping
                              ? _openMistralConfirmation
                              : null,
                          child: Text(
                            'Proposer un mapping avec Mistral',
                            style: TextStyle(
                              color:
                                  canRunMistralGrouping ? _tsxAccent : subtle,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.only_selected'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed: () {
                            setState(() {
                              _onlySelected = !_onlySelected;
                            });
                          },
                          child: Text(
                            _onlySelected
                                ? 'Tout afficher'
                                : 'Sélection seulement',
                            style: const TextStyle(
                              color: _tsxAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          key: const ValueKey(
                              'tiled_tsx_animation_browser.clear_selection'),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          onPressed:
                              _selectedIds.isEmpty ? null : _clearSelection,
                          child: Text(
                            'Vider',
                            style: TextStyle(
                              color: _selectedIds.isEmpty ? subtle : _tsxAccent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    );
                    if (toolbarConstraints.maxWidth < 900) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          selectionText,
                          const SizedBox(height: 4),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: selectionText),
                        actions,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (_selectedIds.isNotEmpty && !hasMistralKey) ...[
                  const _StatusLine(
                    text:
                        'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.',
                    color: Color(0xFFFACC15),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_mistralConfirmOpen ||
                    _mistralPending ||
                    _mistralResult != null) ...[
                  _TiledTsxMistralGroupingPanel(
                    result: _mistralResult,
                    pending: _mistralPending,
                    confirming: _mistralConfirmOpen,
                    onConfirm: _runMistralGrouping,
                    onCancel: () {
                      setState(() {
                        _mistralConfirmOpen = false;
                        if (!_mistralPending) {
                          _mistralResult = null;
                        }
                      });
                    },
                    onApplyReliable: _applyReliableMistralSuggestions,
                    onApplyAll: _applyAllMistralSuggestions,
                    onAccept: _applyMistralSuggestion,
                    onReject: _rejectMistralSuggestion,
                    atlas: widget.atlas,
                    animations: widget.animations,
                    atlasImageBytes: widget.atlasImageBytes,
                  ),
                  const SizedBox(height: 10),
                ],
                if (_presetBuilderOpen) ...[
                  _TiledTsxSurfacePresetBuilderPanel(
                    selectedAnimationIds: _selectedIds,
                    idController: _presetId,
                    nameController: _presetName,
                    categoryController: _presetCategory,
                    sortOrderController: _presetSortOrder,
                    roleControllers: _roleControllers,
                    roleSources: _roleSources,
                    atlas: widget.atlas,
                    animations: widget.animations,
                    atlasImageBytes: widget.atlasImageBytes,
                    errors: _presetBuilderErrors,
                    warnings: _presetBuilderWarnings,
                    note: _presetBuilderNote,
                    onCreate: _createPresetFromBuilder,
                    onRoleAssignmentsChanged: _replaceRoleAssignments,
                    onClose: () {
                      setState(() {
                        _presetBuilderOpen = false;
                        _presetBuilderErrors = const <String>[];
                        _presetBuilderWarnings = const <String>[];
                        _presetBuilderNote = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                if (!_presetBuilderOpen)
                  SizedBox(height: bodyHeight, child: animationBody),
              ],
            ),
          ),
        );
      },
    );
  }

  ProjectSurfaceAnimation? _activeAnimation() {
    final id = _activeAnimationId;
    if (id == null) {
      return null;
    }
    for (final animation in widget.animations) {
      if (animation.id == id) {
        return animation;
      }
    }
    return null;
  }

  void _activateAnimation(String id) {
    setState(() {
      _activeAnimationId = id;
    });
  }

  void _toggleSelection(String id) {
    final next = Set<String>.of(_selectedIds);
    if (!next.add(id)) {
      next.remove(id);
    }
    setState(() {
      _selectedIds = next;
      _activeAnimationId = id;
    });
    widget.onSelectionChanged?.call(Set<String>.unmodifiable(next));
  }

  void _clearSelection() {
    setState(() {
      _selectedIds = const <String>{};
      _onlySelected = false;
      _presetBuilderOpen = false;
    });
    widget.onSelectionChanged?.call(const <String>{});
  }

  ProjectSurfaceCatalog _effectiveCatalog() {
    final provided = widget.catalog;
    if (provided != null) {
      return provided;
    }
    return ProjectSurfaceCatalog(
      atlases: widget.atlas == null
          ? const <ProjectSurfaceAtlas>[]
          : <ProjectSurfaceAtlas>[widget.atlas!],
      animations: widget.animations,
    );
  }

  void _resetPresetDefaults() {
    final catalog = _effectiveCatalog();
    _presetId.text = 'tsx-surface-${catalog.presetCount}';
    _presetName.text = 'Surface TSX';
    _presetCategory.text = '';
    _presetSortOrder.text = '${catalog.presetCount}';
    for (final controller in _roleControllers.values) {
      controller.text = '';
    }
    _roleSources.clear();
  }

  void _openPresetBuilder() {
    setState(() {
      _presetBuilderOpen = true;
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = const <String>[];
      _presetBuilderNote = null;
    });
  }

  void _openMistralConfirmation() {
    setState(() {
      _mistralConfirmOpen = true;
      _mistralResult = null;
    });
  }

  Future<void> _runMistralGrouping() async {
    final atlas = widget.atlas;
    if (atlas == null) {
      setState(() {
        _mistralConfirmOpen = false;
        _mistralPending = false;
        _mistralResult = const TiledTsxMistralGroupingResult(
          suggestions: <TiledTsxRoleAnimationSuggestion>[],
          rejectedAnimationIds: <String>[],
          warnings: <String>[
            'Atlas Surface indisponible : analyse Mistral impossible.',
          ],
        );
      });
      return;
    }
    final selectedAnimations = _selectedAnimations();
    if (selectedAnimations.isEmpty) {
      return;
    }

    setState(() {
      _mistralConfirmOpen = false;
      _mistralPending = true;
      _mistralResult = null;
    });

    final request = TiledTsxMistralGroupingRequest(
      animations: selectedAnimations,
      tileWidth: atlas.geometry.tileSize.width,
      tileHeight: atlas.geometry.tileSize.height,
      atlasColumns: atlas.geometry.gridSize.columns,
      atlasRows: atlas.geometry.gridSize.rows,
      availableRoles: standardSurfaceVariantRoleOrder,
    );
    final suggester =
        widget.groupingSuggester ?? TiledTsxMistralAnimationGroupingSuggester();
    late final TiledTsxMistralGroupingResult result;
    try {
      result = await suggester.suggest(
        apiKey: resolveEditorMistralApiKey(widget.projectSettings),
        request: request,
        atlasImageBytes: widget.atlasImageBytes,
      );
    } on TimeoutException {
      result = const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>[
          'Mistral n’a pas répondu à temps. Aucune modification n’a été appliquée.',
        ],
      );
    } catch (_) {
      result = const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[],
        rejectedAnimationIds: <String>[],
        warnings: <String>[
          'Analyse Mistral impossible. Aucune modification n’a été appliquée.',
        ],
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _mistralPending = false;
      _mistralResult = result;
    });
  }

  List<ProjectSurfaceAnimation> _selectedAnimations() {
    return widget.animations
        .where((animation) => _selectedIds.contains(animation.id))
        .toList(growable: false);
  }

  void _applyMistralSuggestion(TiledTsxRoleAnimationSuggestion suggestion) {
    setState(() {
      _presetBuilderOpen = true;
      _roleControllers[suggestion.role]!.text = suggestion.animationId;
      _roleSources[suggestion.role] = TiledTsxRoleAssignmentMeta(
        source: TiledTsxRoleAssignmentSource.mistral,
        confidence: suggestion.confidence,
      );
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = const <String>[];
      _presetBuilderNote = 'Suggestion Mistral appliquée au draft local.';
    });
  }

  void _applyReliableMistralSuggestions() {
    final result = _mistralResult;
    if (result == null) {
      return;
    }
    setState(() {
      _presetBuilderOpen = true;
      for (final suggestion in result.reliableSuggestions) {
        _roleControllers[suggestion.role]!.text = suggestion.animationId;
        _roleSources[suggestion.role] = TiledTsxRoleAssignmentMeta(
          source: TiledTsxRoleAssignmentSource.mistral,
          confidence: suggestion.confidence,
        );
      }
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = const <String>[];
      _presetBuilderNote =
          'Suggestions Mistral fiables appliquées au draft local.';
    });
  }

  void _applyAllMistralSuggestions() {
    final result = _mistralResult;
    if (result == null) {
      return;
    }
    setState(() {
      _presetBuilderOpen = true;
      for (final suggestion in result.suggestions) {
        _roleControllers[suggestion.role]!.text = suggestion.animationId;
        _roleSources[suggestion.role] = TiledTsxRoleAssignmentMeta(
          source: TiledTsxRoleAssignmentSource.mistral,
          confidence: suggestion.confidence,
        );
      }
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = const <String>[];
      _presetBuilderNote = 'Suggestions Mistral appliquées au draft local.';
    });
  }

  void _rejectMistralSuggestion(TiledTsxRoleAnimationSuggestion suggestion) {
    final result = _mistralResult;
    if (result == null) {
      return;
    }
    setState(() {
      _mistralResult = TiledTsxMistralGroupingResult(
        suggestions: List<TiledTsxRoleAnimationSuggestion>.unmodifiable(
          result.suggestions.where((item) => item != suggestion),
        ),
        rejectedAnimationIds: result.rejectedAnimationIds,
        warnings: result.warnings,
      );
    });
  }

  Map<SurfaceVariantRole, String> _currentRoleAnimationIds() {
    return <SurfaceVariantRole, String>{
      for (final entry in _roleControllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };
  }

  void _replaceRoleAssignments(Map<SurfaceVariantRole, String> next) {
    final previous = _currentRoleAnimationIds();
    setState(() {
      for (final role in standardSurfaceVariantRoleOrder) {
        final value = next[role];
        _roleControllers[role]!.text = value ?? '';
        if (value == null || value.trim().isEmpty) {
          _roleSources.remove(role);
        } else if (previous[role] != value) {
          _roleSources[role] = const TiledTsxRoleAssignmentMeta(
            source: TiledTsxRoleAssignmentSource.manual,
          );
        }
      }
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = const <String>[];
      _presetBuilderNote = null;
    });
  }

  void _createPresetFromBuilder() {
    final sortOrder = int.tryParse(_presetSortOrder.text.trim());
    if (sortOrder == null) {
      setState(() {
        _presetBuilderErrors = const <String>['Ordre invalide.'];
        _presetBuilderWarnings = const <String>[];
        _presetBuilderNote = null;
      });
      return;
    }

    final roleAnimationIds = <SurfaceVariantRole, String>{
      for (final entry in _roleControllers.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
    };
    final nonSelected = <String>[];
    for (final entry in roleAnimationIds.entries) {
      if (!_selectedIds.contains(entry.value)) {
        nonSelected.add(
          'Animation non sélectionnée pour ${SurfaceStudioRoleLabels.labelForRole(entry.key)} : ${entry.value}.',
        );
      }
    }
    if (nonSelected.isNotEmpty) {
      setState(() {
        _presetBuilderErrors = List<String>.unmodifiable(nonSelected);
        _presetBuilderWarnings = const <String>[];
        _presetBuilderNote = null;
      });
      return;
    }

    final catalog = _effectiveCatalog();
    final draft = TiledTsxSurfacePresetDraft(
      id: _presetId.text,
      name: _presetName.text,
      categoryId: _presetCategory.text,
      sortOrder: sortOrder,
      roleAnimationIds: roleAnimationIds,
    );
    final validation = validateTiledTsxSurfacePresetDraft(
      draft: draft,
      catalog: catalog,
    );
    if (!validation.canCreate) {
      setState(() {
        _presetBuilderErrors = validation.errors;
        _presetBuilderWarnings = validation.warnings;
        _presetBuilderNote = null;
      });
      return;
    }

    final preset = buildTiledTsxSurfacePresetFromDraft(
      draft: draft,
      catalog: catalog,
    );
    final next = surfaceStudioAppendPresetToWorkCatalog(
      catalog: catalog,
      preset: preset,
    );
    widget.onSurfaceCatalogChanged?.call(next);
    setState(() {
      _presetBuilderErrors = const <String>[];
      _presetBuilderWarnings = validation.warnings;
      _presetBuilderNote =
          'Preset ${preset.id} ajouté au catalogue de travail.';
    });
  }
}

class _TiledTsxSurfacePresetBuilderPanel extends StatelessWidget {
  const _TiledTsxSurfacePresetBuilderPanel({
    required this.selectedAnimationIds,
    required this.idController,
    required this.nameController,
    required this.categoryController,
    required this.sortOrderController,
    required this.roleControllers,
    required this.roleSources,
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
    required this.errors,
    required this.warnings,
    required this.note,
    required this.onCreate,
    required this.onRoleAssignmentsChanged,
    required this.onClose,
  });

  final Set<String> selectedAnimationIds;
  final TextEditingController idController;
  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController sortOrderController;
  final Map<SurfaceVariantRole, TextEditingController> roleControllers;
  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;
  final List<String> errors;
  final List<String> warnings;
  final String? note;
  final VoidCallback onCreate;
  final ValueChanged<Map<SurfaceVariantRole, String>> onRoleAssignmentsChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('tiled_tsx_surface_preset_builder.panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 310),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Créer une surface depuis animations TSX',
                      style: TextStyle(
                        color: label,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CupertinoButton.filled(
                    key: const ValueKey(
                      'tiled_tsx_surface_preset_builder.create',
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    onPressed: onCreate,
                    child: const Text(
                      'Créer le preset',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    onPressed: onClose,
                    child: const Text(
                      'Masquer',
                      style: TextStyle(
                        color: _tsxAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Aucun rôle n’est deviné : associez explicitement chaque rôle à une animation sélectionnée.',
                style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
              ),
              const SizedBox(height: 8),
              Text(
                '${selectedAnimationIds.length} animations sélectionnées',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final id in selectedAnimationIds)
                    _SelectedAnimationPill(id: id),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.id',
                    label: 'Identifiant surface',
                    controller: idController,
                    width: 210,
                  ),
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.name',
                    label: 'Nom surface',
                    controller: nameController,
                    width: 210,
                  ),
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.category',
                    label: 'Catégorie',
                    controller: categoryController,
                    width: 170,
                  ),
                  _BuilderTextField(
                    keyName: 'tiled_tsx_surface_preset_builder.sort_order',
                    label: 'Ordre',
                    controller: sortOrderController,
                    width: 96,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Mapping rôles → animations',
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              TiledTsxRoleMappingBuilder(
                atlas: atlas,
                animations: animations,
                selectedAnimationIds: selectedAnimationIds,
                roleAnimationIds: {
                  for (final entry in roleControllers.entries)
                    if (entry.value.text.trim().isNotEmpty)
                      entry.key: entry.value.text.trim(),
                },
                roleSources: roleSources,
                atlasImageBytes: atlasImageBytes,
                onChanged: onRoleAssignmentsChanged,
              ),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final error in errors)
                  _StatusLine(text: error, color: const Color(0xFFF87171)),
              ],
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 4),
                for (final warning in warnings)
                  _StatusLine(text: warning, color: const Color(0xFFFACC15)),
              ],
              if (note != null) ...[
                const SizedBox(height: 4),
                _StatusLine(text: note!, color: _tsxAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedAnimationPill extends StatelessWidget {
  const _SelectedAnimationPill({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _tsxAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _tsxAccent.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          id,
          style: const TextStyle(
            color: _tsxAccent,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BuilderTextField extends StatelessWidget {
  const _BuilderTextField({
    required this.keyName,
    required this.label,
    required this.controller,
    required this.width,
  });

  final String keyName;
  final String label;
  final TextEditingController controller;
  final double width;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          CupertinoTextField(
            key: ValueKey(keyName),
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _TiledTsxMistralGroupingPanel extends StatelessWidget {
  const _TiledTsxMistralGroupingPanel({
    required this.result,
    required this.pending,
    required this.confirming,
    required this.onConfirm,
    required this.onCancel,
    required this.onApplyReliable,
    required this.onApplyAll,
    required this.onAccept,
    required this.onReject,
    required this.atlas,
    required this.animations,
    required this.atlasImageBytes,
  });

  final TiledTsxMistralGroupingResult? result;
  final bool pending;
  final bool confirming;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onApplyReliable;
  final VoidCallback onApplyAll;
  final ValueChanged<TiledTsxRoleAnimationSuggestion> onAccept;
  final ValueChanged<TiledTsxRoleAnimationSuggestion> onReject;
  final ProjectSurfaceAtlas? atlas;
  final List<ProjectSurfaceAnimation> animations;
  final Uint8List? atlasImageBytes;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      key: const ValueKey('tiled_tsx_mistral_grouping.panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            confirming || pending ? 'Assistant Mistral' : 'Suggestions Mistral',
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mistral analyse uniquement les animations TSX sélectionnées et propose role → animationId. Aucun preset n’est créé automatiquement.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          if (confirming) _buildConfirmation(),
          if (pending) _buildProgress(label),
          if (!confirming && !pending && result != null)
            _buildReview(label, subtle, result!),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cette analyse enverra une planche visuelle des animations sélectionnées au fournisseur IA configuré. Aucune modification ne sera appliquée automatiquement.',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            CupertinoButton.filled(
              key: const ValueKey('tiled_tsx_mistral_grouping.confirm'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: onConfirm,
              child: const Text(
                'Confirmer l’analyse IA',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: onCancel,
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: _tsxAccent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgress(Color label) {
    return Row(
      key: const ValueKey('tiled_tsx_mistral_grouping.progress'),
      children: [
        const CupertinoActivityIndicator(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mistral analyse les animations sélectionnées avec un niveau de réflexion élevé.',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(
    Color label,
    Color subtle,
    TiledTsxMistralGroupingResult result,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_groupMistralWarnings(result.warnings).hasWarnings) ...[
          _MistralWarningSummary(
            groupedWarnings: _groupMistralWarnings(result.warnings),
          ),
          const SizedBox(height: 6),
        ],
        if (result.suggestions.isEmpty)
          Text(
            'Aucune suggestion exploitable.',
            style: TextStyle(color: subtle, fontSize: 11.5),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              CupertinoButton(
                key: const ValueKey(
                  'tiled_tsx_mistral_grouping.apply_reliable',
                ),
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onApplyReliable,
                child: const Text(
                  'Appliquer les suggestions fiables au draft',
                  style: TextStyle(
                    color: _tsxAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                key: const ValueKey('tiled_tsx_mistral_grouping.apply_all'),
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onApplyAll,
                child: const Text(
                  'Tout appliquer',
                  style: TextStyle(
                    color: _tsxAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onCancel,
                child: const Text(
                  'Annuler',
                  style: TextStyle(
                    color: _tsxAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final suggestion in result.suggestions)
            _TiledTsxMistralSuggestionRow(
              suggestion: suggestion,
              label: label,
              subtle: subtle,
              animation: _animationForSuggestion(suggestion),
              atlas: atlas,
              atlasImageBytes: atlasImageBytes,
              onAccept: () => onAccept(suggestion),
              onReject: () => onReject(suggestion),
            ),
        ],
      ],
    );
  }

  ProjectSurfaceAnimation? _animationForSuggestion(
    TiledTsxRoleAnimationSuggestion suggestion,
  ) {
    for (final animation in animations) {
      if (animation.id == suggestion.animationId) {
        return animation;
      }
    }
    return null;
  }
}

class _TiledTsxMistralSuggestionRow extends StatelessWidget {
  const _TiledTsxMistralSuggestionRow({
    required this.suggestion,
    required this.label,
    required this.subtle,
    required this.animation,
    required this.atlas,
    required this.atlasImageBytes,
    required this.onAccept,
    required this.onReject,
  });

  final TiledTsxRoleAnimationSuggestion suggestion;
  final Color label;
  final Color subtle;
  final ProjectSurfaceAnimation? animation;
  final ProjectSurfaceAtlas? atlas;
  final Uint8List? atlasImageBytes;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final roleLabel = suggestion.role == SurfaceVariantRole.isolated
        ? 'Plein(center)'
        : SurfaceStudioRoleLabels.labelForRole(suggestion.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: animation == null
                    ? const _SmallPreviewFallback()
                    : TiledTsxAnimationTilePreview(
                        atlas: atlas,
                        animation: animation!,
                        atlasImageBytes: atlasImageBytes,
                        compact: true,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleLabel,
                      style: TextStyle(
                        color: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      suggestion.animationId,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: label,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Confiance : ${suggestion.confidence.name}',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11.2,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Evidence : ${suggestion.evidenceAnimationIds.join(', ')}',
            style: TextStyle(color: subtle, fontSize: 11.2, height: 1.3),
          ),
          Text(
            suggestion.reason,
            style: TextStyle(color: subtle, fontSize: 11.2, height: 1.3),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CupertinoButton(
                key: ValueKey(
                  'tiled_tsx_mistral_grouping.accept.${suggestion.role.name}',
                ),
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onAccept,
                child: const Text(
                  'Accepter',
                  style: TextStyle(
                    color: _tsxAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CupertinoButton(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: onReject,
                child: const Text(
                  'Rejeter',
                  style: TextStyle(
                    color: _tsxAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallPreviewFallback extends StatelessWidget {
  const _SmallPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101820),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Text(
            'Aperçu indisponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MistralWarningSummary extends StatelessWidget {
  const _MistralWarningSummary({required this.groupedWarnings});

  final _GroupedMistralWarnings groupedWarnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFACC15).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Suggestions ignorées',
            style: TextStyle(
              color: Color(0xFFFACC15),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          for (final entry in groupedWarnings.duplicateRoleCounts.entries)
            Text(
              '${entry.value} suggestions ont été ignorées car elles proposaient déjà ${_mistralRoleLabel(entry.key)}.',
              style: const TextStyle(
                color: Color(0xFFFACC15),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          for (final warning in groupedWarnings.otherWarnings)
            Text(
              warning,
              style: const TextStyle(
                color: Color(0xFFFACC15),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}

final class _GroupedMistralWarnings {
  const _GroupedMistralWarnings({
    required this.duplicateRoleCounts,
    required this.otherWarnings,
  });

  final Map<String, int> duplicateRoleCounts;
  final List<String> otherWarnings;

  bool get hasWarnings =>
      duplicateRoleCounts.isNotEmpty || otherWarnings.isNotEmpty;
}

_GroupedMistralWarnings _groupMistralWarnings(List<String> warnings) {
  final duplicateRoleCounts = <String, int>{};
  final otherWarnings = <String>[];
  final duplicateRoleRegex =
      RegExp(r'^Rôle Mistral dupliqué rejeté : ([A-Za-z0-9_]+)\.$');
  for (final warning in warnings) {
    final match = duplicateRoleRegex.firstMatch(warning);
    if (match == null) {
      otherWarnings.add(warning);
      continue;
    }
    final roleName = match.group(1)!;
    duplicateRoleCounts[roleName] = (duplicateRoleCounts[roleName] ?? 0) + 1;
  }
  return _GroupedMistralWarnings(
    duplicateRoleCounts: Map<String, int>.unmodifiable(duplicateRoleCounts),
    otherWarnings: List<String>.unmodifiable(otherWarnings),
  );
}

String _mistralRoleLabel(String roleName) {
  for (final role in standardSurfaceVariantRoleOrder) {
    if (role.name == roleName) {
      if (role == SurfaceVariantRole.isolated) {
        return 'Plein(center)';
      }
      return SurfaceStudioRoleLabels.labelForRole(role);
    }
  }
  return roleName;
}

class TiledTsxSurfaceAnimationPreview extends StatefulWidget {
  const TiledTsxSurfaceAnimationPreview({
    super.key,
    required this.atlas,
    required this.animation,
    this.atlasImageBytes,
  });

  final ProjectSurfaceAtlas? atlas;
  final ProjectSurfaceAnimation animation;
  final Uint8List? atlasImageBytes;

  @override
  State<TiledTsxSurfaceAnimationPreview> createState() =>
      _TiledTsxSurfaceAnimationPreviewState();
}

class _TiledTsxSurfaceAnimationPreviewState
    extends State<TiledTsxSurfaceAnimationPreview> {
  int _frameIndex = 0;
  bool _playing = false;
  Timer? _timer;
  ui.Image? _decoded;
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant TiledTsxSurfaceAnimationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _timer?.cancel();
      _playing = false;
      _frameIndex = 0;
    } else if (_frameIndex >= widget.animation.frameCount) {
      _frameIndex = 0;
    }
    if (widget.atlasImageBytes != oldWidget.atlasImageBytes) {
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _decoded?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final frames = widget.animation.timeline.frames;
    final frame = frames[_frameIndex.clamp(0, frames.length - 1).toInt()];
    return Container(
      key: const ValueKey('tiled_tsx_animation_preview.root'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.animation.id,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.animation.frameCount} frames · ${widget.animation.totalDurationMs} ms',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF101820),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: EditorChrome.editorIslandRim(context)
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  child: _buildVisualPreview(frame),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Frame ${_frameIndex + 1} / ${frames.length}',
            key: const ValueKey('tiled_tsx_animation_preview.frame_label'),
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'column ${frame.tileRef.column}, row ${frame.tileRef.row}',
            style: TextStyle(color: label, fontSize: 11.5, height: 1.35),
          ),
          Text(
            '${frame.durationMs} ms',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PreviewButton(
                key: const ValueKey('tiled_tsx_animation_preview.previous'),
                label: 'Précédent',
                onPressed: _previousFrame,
              ),
              const SizedBox(width: 8),
              _PreviewButton(
                key: const ValueKey('tiled_tsx_animation_preview.next'),
                label: 'Suivant',
                onPressed: _nextFrame,
              ),
              const SizedBox(width: 8),
              _PreviewButton(
                key: const ValueKey('tiled_tsx_animation_preview.play_pause'),
                label: _playing ? 'Pause' : 'Play',
                onPressed: _togglePlay,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FrameStrip(
            frames: frames,
            selectedIndex: _frameIndex,
            onSelected: (index) => setState(() => _frameIndex = index),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPreview(SurfaceAnimationFrame frame) {
    final atlas = widget.atlas;
    final decoded = _decoded;
    if (widget.atlasImageBytes == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Image atlas indisponible — frames listées sans aperçu visuel.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA6B2),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    if (atlas == null || decoded == null) {
      return const Center(
        child: Text(
          'Décodage de l’atlas…',
          style: TextStyle(color: Color(0xFF9AA6B2), fontSize: 11.5),
        ),
      );
    }
    final tileWidth = atlas.geometry.tileSize.width;
    final tileHeight = atlas.geometry.tileSize.height;
    final source = Rect.fromLTWH(
      (frame.tileRef.column * tileWidth).toDouble(),
      (frame.tileRef.row * tileHeight).toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
    return CustomPaint(
      painter: _TiledTsxFrameCropPainter(image: decoded, source: source),
      child: const SizedBox.expand(),
    );
  }

  void _decodeImage() {
    final bytes = widget.atlasImageBytes;
    if (bytes == null || bytes.isEmpty) {
      _decodedBytes = null;
      _decoded?.dispose();
      _decoded = null;
      return;
    }
    if (identical(bytes, _decodedBytes)) {
      return;
    }
    _decodedBytes = bytes;
    ui.decodeImageFromList(bytes, (image) {
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _decoded?.dispose();
        _decoded = image;
      });
    });
  }

  void _previousFrame() {
    setState(() {
      _playing = false;
      _timer?.cancel();
      _frameIndex = (_frameIndex - 1) % widget.animation.frameCount;
    });
  }

  void _nextFrame() {
    setState(() {
      _playing = false;
      _timer?.cancel();
      _frameIndex = (_frameIndex + 1) % widget.animation.frameCount;
    });
  }

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(
        milliseconds: widget.animation.timeline.frames[_frameIndex].durationMs,
      ),
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _frameIndex = (_frameIndex + 1) % widget.animation.frameCount;
        });
      },
    );
  }
}

class _AnimationList extends StatelessWidget {
  const _AnimationList({
    required this.items,
    required this.selectedIds,
    required this.activeAnimationId,
    required this.onToggleSelection,
    required this.onActivate,
  });

  final List<TiledTsxAnimationBrowserItem> items;
  final Set<String> selectedIds;
  final String? activeAnimationId;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onActivate;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Aucune animation TSX ne correspond au filtre.',
          style: TextStyle(color: subtle, fontSize: 12),
        ),
      );
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _AnimationItemCard(
          item: item,
          selected: selectedIds.contains(item.animationId),
          active: activeAnimationId == item.animationId,
          onToggleSelection: () => onToggleSelection(item.animationId),
          onActivate: () => onActivate(item.animationId),
        );
      },
    );
  }
}

class _AnimationItemCard extends StatelessWidget {
  const _AnimationItemCard({
    required this.item,
    required this.selected,
    required this.active,
    required this.onToggleSelection,
    required this.onActivate,
  });

  final TiledTsxAnimationBrowserItem item;
  final bool selected;
  final bool active;
  final VoidCallback onToggleSelection;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final baseBg = EditorChrome.islandFillElevated(context);
    return GestureDetector(
      key: ValueKey('tiled_tsx_animation_browser.item.${item.animationId}'),
      behavior: HitTestBehavior.opaque,
      onTap: onActivate,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? Color.lerp(baseBg, _tsxAccent, 0.08)! : baseBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? Color.lerp(
                    EditorChrome.editorIslandRim(context),
                    _tsxAccent,
                    0.48,
                  )!
                : EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SelectionBox(
              key: ValueKey(
                'tiled_tsx_animation_browser.checkbox.${item.animationId}',
              ),
              selected: selected,
              onTap: onToggleSelection,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.animationId,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'base tile: ${item.baseTileId}',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.2,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    '${item.frameCount} frames · ${item.durationTotalMs} ms',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.2,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    'first frame: column ${item.firstFrameColumn}, row ${item.firstFrameRow}',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11.2,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      key: const ValueKey('tiled_tsx_animation_browser.search'),
      controller: controller,
      onChanged: onChanged,
      placeholder: 'Rechercher une animation, un id ou un tile id…',
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
        ),
      ),
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12.5,
      ),
      placeholderStyle: TextStyle(
        color: EditorChrome.subtleLabel(context),
        fontSize: 12.5,
      ),
    );
  }
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({
    super.key,
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _tsxAccent : const Color(0x00000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color:
                selected ? _tsxAccent : EditorChrome.editorIslandRim(context),
          ),
        ),
        child: selected
            ? const Icon(
                CupertinoIcons.check_mark,
                color: Color(0xFF061A1A),
                size: 14,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _tsxAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _tsxAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      color: _tsxAccent.withValues(alpha: 0.16),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: _tsxAccent,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FrameStrip extends StatelessWidget {
  const _FrameStrip({
    required this.frames,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SurfaceAnimationFrame> frames;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: frames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final frame = frames[index];
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              width: 82,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected
                    ? _tsxAccent.withValues(alpha: 0.15)
                    : EditorChrome.islandFillElevated(context)
                        .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? _tsxAccent
                      : EditorChrome.editorIslandRim(context)
                          .withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: selected ? _tsxAccent : subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'column ${frame.tileRef.column}, row ${frame.tileRef.row}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subtle, fontSize: 9.5, height: 1.1),
                  ),
                  Text(
                    '${frame.durationMs} ms',
                    style: TextStyle(color: subtle, fontSize: 9.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.subtle});

  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sélectionnez une animation TSX pour inspecter ses frames.',
        style: TextStyle(color: subtle, fontSize: 12),
      ),
    );
  }
}

class _TiledTsxFrameCropPainter extends CustomPainter {
  const _TiledTsxFrameCropPainter({
    required this.image,
    required this.source,
  });

  final ui.Image image;
  final Rect source;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _TiledTsxFrameCropPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.source != source;
  }
}

String _selectionLabel(int count) {
  if (count == 0) {
    return '0 animations sélectionnées';
  }
  if (count == 1) {
    return '1 animation sélectionnée';
  }
  return '$count animations sélectionnées';
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart';

void main() {
  testWidgets('shows visual role slots and maps roles through a picker',
      (tester) async {
    Map<SurfaceVariantRole, String>? changed;

    await tester.pumpWidget(
      _wrap(
        TiledTsxRoleMappingBuilder(
          atlas: _atlas(),
          animations: _animations(),
          selectedAnimationIds: const {
            'tech-animations-tile-99',
            'tech-animations-tile-105',
          },
          roleAnimationIds: const {
            SurfaceVariantRole.horizontal: 'tech-animations-tile-105',
          },
          roleSources: const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{},
          onChanged: (next) => changed = next,
        ),
      ),
    );

    expect(find.text('Surface principale'), findsOneWidget);
    expect(find.text('Bords'), findsOneWidget);
    expect(find.text('Coins externes'), findsOneWidget);
    expect(find.text('Coins internes'), findsOneWidget);
    expect(find.text('Jonctions'), findsOneWidget);
    expect(find.text('Plein(center)'), findsOneWidget);
    expect(find.text('Horizontal'), findsOneWidget);
    expect(find.text('Vertical'), findsOneWidget);
    expect(find.text('Bord haut'), findsOneWidget);
    expect(find.text('Coin haut gauche'), findsOneWidget);
    expect(find.text('Croix'), findsOneWidget);
    expect(find.text('Non assigné'), findsWidgets);
    expect(find.text('tech-animations-tile-105'), findsWidgets);
    expect(find.text('1 frame · 100 ms'), findsWidgets);
    expect(find.text('Aperçu indisponible'), findsWidgets);
    expect(
      find.byKey(
        const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choisir une animation pour Plein(center)'), findsOne);
    await tester.enterText(
      find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.search.isolated'),
      ),
      '99',
    );
    await tester.pumpAndSettle();
    expect(find.text('tech-animations-tile-99'), findsWidgets);

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed![SurfaceVariantRole.isolated], 'tech-animations-tile-99');
    expect(changed![SurfaceVariantRole.horizontal], 'tech-animations-tile-105');

    await tester.tap(
      find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.clear.horizontal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed!.containsKey(SurfaceVariantRole.horizontal), isFalse);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 1200, height: 900, child: child),
    ),
  );
}

ProjectSurfaceAtlas _atlas() {
  return ProjectSurfaceAtlas(
    id: 'tech-animations',
    name: 'TECH-Animations',
    tilesetId: 'tech-nature-animations',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
      layout: SurfaceAtlasLayout.grid,
    ),
  );
}

List<ProjectSurfaceAnimation> _animations() {
  return [
    _animation('tech-animations-tile-99', 1, 1),
    _animation('tech-animations-tile-105', 7, 1),
  ];
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

void main() {
  testWidgets('Mistral review shows visual suggestions and grouped duplicates',
      (tester) async {
    final catalog = _miniCatalog();
    ProjectSurfaceCatalog? changedCatalog;

    await tester.pumpWidget(
      _wrap(
        TiledTsxAnimationBrowser(
          atlas: catalog.atlases.single,
          animations: catalog.animations,
          catalog: catalog,
          projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
          groupingSuggester: _DuplicateWarningGroupingSuggester(),
          onSurfaceCatalogChanged: (next) => changedCatalog = next,
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final aiButton = find.byKey(
      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
    );
    await tester.ensureVisible(aiButton);
    await tester.tap(aiButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('tiled_tsx_mistral_grouping.confirm')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggestions Mistral'), findsOneWidget);
    expect(find.text('Plein(center)'), findsWidgets);
    expect(find.text('tech-animations-tile-99'), findsWidgets);
    expect(find.text('Confiance : high'), findsOneWidget);
    expect(find.text('Aperçu indisponible'), findsWidgets);
    expect(find.text('Suggestions ignorées'), findsOneWidget);
    expect(
      find.text(
        '4 suggestions ont été ignorées car elles proposaient déjà Plein(center).',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Rôle Mistral dupliqué rejeté : isolated.'),
      findsNothing,
    );
    expect(changedCatalog, isNull);

    await tester.tap(
      find.byKey(
        const ValueKey('tiled_tsx_mistral_grouping.accept.isolated'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.panel')),
      findsOneWidget,
    );
    expect(find.text('Source : Mistral'), findsOneWidget);
    expect(find.text('Créer le preset'), findsOneWidget);
    expect(changedCatalog, isNull);
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 1100, height: 920, child: child),
      ),
    ),
  );
}

final class _DuplicateWarningGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    return const TiledTsxMistralGroupingResult(
      suggestions: <TiledTsxRoleAnimationSuggestion>[
        TiledTsxRoleAnimationSuggestion(
          role: SurfaceVariantRole.isolated,
          animationId: 'tech-animations-tile-99',
          confidence: SurfaceStudioMappingSuggestionConfidence.high,
          reason: 'Full repeatable water tile.',
          evidenceAnimationIds: <String>['tech-animations-tile-99'],
        ),
      ],
      rejectedAnimationIds: <String>[],
      warnings: <String>[
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
        'Rôle Mistral dupliqué rejeté : isolated.',
      ],
    );
  }
}

ProjectSurfaceCatalog _miniCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'tech-animations',
        name: 'TECH-Animations',
        tilesetId: 'tech-nature-animations',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [
      _animation('tech-animations-tile-99'),
      _animation('tech-animations-tile-105'),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: 1,
            row: 1,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';

void main() {
  testWidgets(
    'creates a preset from selected TSX animations only after explicit role mapping',
    (tester) async {
      final catalog = _miniCatalog();
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxAnimationBrowser(
            atlas: catalog.atlases.single,
            animations: catalog.animations,
            catalog: catalog,
            onSurfaceCatalogChanged: (next) => changedCatalog = next,
          ),
        ),
      );

      final createSurface = find.byKey(
        const ValueKey('tiled_tsx_animation_browser.create_surface'),
      );
      await tester.ensureVisible(createSurface);
      await tester.tap(createSurface);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.panel'),
        ),
        findsNothing,
      );

      final tile99Checkbox = find.byKey(
        const ValueKey(
            'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99'),
      );
      await tester.ensureVisible(tile99Checkbox);
      await tester.tap(tile99Checkbox);
      await tester.pumpAndSettle();

      await tester.ensureVisible(createSurface);
      await tester.tap(createSurface);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.panel'),
        ),
        findsOneWidget,
      );

      final createPreset = find.byKey(
        const ValueKey('tiled_tsx_surface_preset_builder.create'),
      );
      await tester.ensureVisible(createPreset);
      await tester.tap(createPreset);
      await tester.pumpAndSettle();

      expect(find.text('Plein(center) obligatoire.'), findsOneWidget);
      expect(changedCatalog, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.id')),
        'water-tsx-surface',
      );
      await tester.enterText(
        find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.name')),
        'Water TSX Surface',
      );
      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
        ),
        findsNothing,
      );

      final pickIsolated = find.byKey(
        const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
      );
      await tester.ensureVisible(pickIsolated);
      await tester.tap(pickIsolated);
      await tester.pumpAndSettle();

      final tile99Option = find.byKey(
        const ValueKey(
          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
        ),
      );
      await tester.ensureVisible(tile99Option);
      await tester.tap(tile99Option);
      await tester.pumpAndSettle();

      await tester.ensureVisible(createPreset);
      await tester.tap(createPreset);
      await tester.pumpAndSettle();

      expect(changedCatalog, isNotNull);
      expect(changedCatalog!.presetCount, 1);
      expect(changedCatalog!.animationCount, catalog.animationCount);
      expect(
        changedCatalog!
            .presetById('water-tsx-surface')!
            .animationIdForRole(SurfaceVariantRole.isolated),
        'tech-animations-tile-99',
      );
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 1100,
          height: 900,
          child: child,
        ),
      ),
    ),
  );
}

ProjectSurfaceCatalog _miniCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'tech-animations',
        name: 'TECH-Animations',
        tilesetId: 'tech-nature-animations',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [
      _animation('tech-animations-tile-99', 1, 1),
      _animation('tech-animations-tile-105', 7, 1),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id, int column, int row) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: column,
            row: row,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
```

### packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

void main() {
  testWidgets('Mistral grouping button requires selection and configured key',
      (tester) async {
    final catalog = _miniCatalog();

    await tester.pumpWidget(
      _wrap(
        TiledTsxAnimationBrowser(
          atlas: catalog.atlases.single,
          animations: catalog.animations,
          catalog: catalog,
          projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
          groupingSuggester: _ImmediateGroupingSuggester(),
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
    );
    await tester.ensureVisible(button);
    expect(tester.widget<CupertinoButton>(button).onPressed, isNull);

    final checkbox = find.byKey(
      const ValueKey(
        'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
      ),
    );
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    await tester.ensureVisible(button);
    expect(tester.widget<CupertinoButton>(button).onPressed, isNotNull);
  });

  testWidgets('Mistral grouping shows missing key message', (tester) async {
    final catalog = _miniCatalog();

    await tester.pumpWidget(
      _wrap(
        TiledTsxAnimationBrowser(
          atlas: catalog.atlases.single,
          animations: catalog.animations,
          catalog: catalog,
          groupingSuggester: _ImmediateGroupingSuggester(),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY.',
      ),
      findsOneWidget,
    );
    final button = find.byKey(
      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
    );
    await tester.ensureVisible(button);
    expect(tester.widget<CupertinoButton>(button).onPressed, isNull);
  });

  testWidgets(
    'Mistral grouping requires confirmation, shows progress, then fills draft only after accept',
    (tester) async {
      final catalog = _miniCatalog();
      final fake = _PendingGroupingSuggester();
      ProjectSurfaceCatalog? changedCatalog;

      await tester.pumpWidget(
        _wrap(
          TiledTsxAnimationBrowser(
            atlas: catalog.atlases.single,
            animations: catalog.animations,
            catalog: catalog,
            projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
            groupingSuggester: fake,
            onSurfaceCatalogChanged: (next) => changedCatalog = next,
          ),
        ),
      );

      final checkbox = find.byKey(
        const ValueKey(
          'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
        ),
      );
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      final aiButton = find.byKey(
        const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
      );
      await tester.ensureVisible(aiButton);
      await tester.tap(aiButton);
      await tester.pumpAndSettle();

      expect(fake.calls, 0);
      expect(find.text('Confirmer l’analyse IA'), findsOneWidget);

      final confirm = find.byKey(
        const ValueKey('tiled_tsx_mistral_grouping.confirm'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pump();

      expect(fake.calls, 1);
      expect(
        find.byKey(const ValueKey('tiled_tsx_mistral_grouping.progress')),
        findsOneWidget,
      );
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(
        find.textContaining('Mistral analyse les animations sélectionnées'),
        findsOneWidget,
      );
      expect(changedCatalog, isNull);

      fake.complete();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('tiled_tsx_mistral_grouping.progress')),
        findsNothing,
      );
      expect(find.text('Suggestions Mistral'), findsOneWidget);
      expect(find.text('tech-animations-tile-99'), findsWidgets);
      expect(changedCatalog, isNull);

      final accept = find.byKey(
        const ValueKey('tiled_tsx_mistral_grouping.accept.isolated'),
      );
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.panel'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('tiled_tsx_role_mapping_builder.slot.isolated'),
        ),
        findsOneWidget,
      );
      expect(find.text('Plein(center)'), findsWidgets);
      expect(find.text('Source : Mistral'), findsOneWidget);
      expect(find.text('Aperçu indisponible'), findsWidgets);
      expect(
        find.byKey(
          const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
        ),
        findsNothing,
      );
      expect(changedCatalog, isNull);
      expect(find.text('Créer le preset'), findsOneWidget);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 1100,
          height: 920,
          child: child,
        ),
      ),
    ),
  );
}

final class _ImmediateGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) async {
    return const TiledTsxMistralGroupingResult(
      suggestions: <TiledTsxRoleAnimationSuggestion>[],
      rejectedAnimationIds: <String>[],
      warnings: <String>[],
    );
  }
}

final class _PendingGroupingSuggester
    implements TiledTsxAnimationGroupingSuggester {
  final Completer<TiledTsxMistralGroupingResult> completer =
      Completer<TiledTsxMistralGroupingResult>();
  int calls = 0;

  @override
  Future<TiledTsxMistralGroupingResult> suggest({
    required String apiKey,
    required TiledTsxMistralGroupingRequest request,
    required Uint8List? atlasImageBytes,
  }) {
    calls++;
    return completer.future;
  }

  void complete() {
    completer.complete(
      const TiledTsxMistralGroupingResult(
        suggestions: <TiledTsxRoleAnimationSuggestion>[
          TiledTsxRoleAnimationSuggestion(
            role: SurfaceVariantRole.isolated,
            animationId: 'tech-animations-tile-99',
            confidence: SurfaceStudioMappingSuggestionConfidence.high,
            reason: 'Full repeatable water tile.',
            evidenceAnimationIds: <String>['tech-animations-tile-99'],
          ),
        ],
        rejectedAnimationIds: <String>[],
        warnings: <String>[],
      ),
    );
  }
}

ProjectSurfaceCatalog _miniCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'tech-animations',
        name: 'TECH-Animations',
        tilesetId: 'tech-nature-animations',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [
      _animation('tech-animations-tile-99'),
      _animation('tech-animations-tile-105'),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tech-animations',
            column: 1,
            row: 1,
          ),
          durationMs: 100,
        ),
      ],
    ),
  );
}
```


## 16. Diffs Complets TSX-7

### Fichiers modifiés suivis

#### git diff -- packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart b/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
index 3334c929..a96a84d8 100644
--- a/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
@@ -12,6 +12,7 @@ import '../surface_studio_vertical_atlas_role_mapping.dart';
 import 'tiled_tsx_animation_browser_models.dart';
 import 'tiled_tsx_mistral_grouping_models.dart';
 import 'tiled_tsx_mistral_grouping_suggester.dart';
+import 'tiled_tsx_role_mapping_builder.dart';
 import 'tiled_tsx_surface_preset_draft.dart';
 
 const Color _tsxAccent = Color(0xFF2DD4BF);
@@ -65,6 +66,7 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
   bool _mistralConfirmOpen = false;
   bool _mistralPending = false;
   TiledTsxMistralGroupingResult? _mistralResult;
+  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> _roleSources = {};
 
   @override
   void initState() {
@@ -362,6 +364,9 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
                     onApplyAll: _applyAllMistralSuggestions,
                     onAccept: _applyMistralSuggestion,
                     onReject: _rejectMistralSuggestion,
+                    atlas: widget.atlas,
+                    animations: widget.animations,
+                    atlasImageBytes: widget.atlasImageBytes,
                   ),
                   const SizedBox(height: 10),
                 ],
@@ -373,10 +378,15 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
                     categoryController: _presetCategory,
                     sortOrderController: _presetSortOrder,
                     roleControllers: _roleControllers,
+                    roleSources: _roleSources,
+                    atlas: widget.atlas,
+                    animations: widget.animations,
+                    atlasImageBytes: widget.atlasImageBytes,
                     errors: _presetBuilderErrors,
                     warnings: _presetBuilderWarnings,
                     note: _presetBuilderNote,
                     onCreate: _createPresetFromBuilder,
+                    onRoleAssignmentsChanged: _replaceRoleAssignments,
                     onClose: () {
                       setState(() {
                         _presetBuilderOpen = false;
@@ -460,6 +470,7 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
     for (final controller in _roleControllers.values) {
       controller.text = '';
     }
+    _roleSources.clear();
   }
 
   void _openPresetBuilder() {
@@ -558,6 +569,10 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
     setState(() {
       _presetBuilderOpen = true;
       _roleControllers[suggestion.role]!.text = suggestion.animationId;
+      _roleSources[suggestion.role] = TiledTsxRoleAssignmentMeta(
+        source: TiledTsxRoleAssignmentSource.mistral,
+        confidence: suggestion.confidence,
+      );
       _presetBuilderErrors = const <String>[];
       _presetBuilderWarnings = const <String>[];
       _presetBuilderNote = 'Suggestion Mistral appliquée au draft local.';
@@ -573,6 +588,10 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
       _presetBuilderOpen = true;
       for (final suggestion in result.reliableSuggestions) {
         _roleControllers[suggestion.role]!.text = suggestion.animationId;
+        _roleSources[suggestion.role] = TiledTsxRoleAssignmentMeta(
+          source: TiledTsxRoleAssignmentSource.mistral,
+          confidence: suggestion.confidence,
+        );
       }
       _presetBuilderErrors = const <String>[];
       _presetBuilderWarnings = const <String>[];
@@ -590,6 +609,10 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
       _presetBuilderOpen = true;
       for (final suggestion in result.suggestions) {
         _roleControllers[suggestion.role]!.text = suggestion.animationId;
+        _roleSources[suggestion.role] = TiledTsxRoleAssignmentMeta(
+          source: TiledTsxRoleAssignmentSource.mistral,
+          confidence: suggestion.confidence,
+        );
       }
       _presetBuilderErrors = const <String>[];
       _presetBuilderWarnings = const <String>[];
@@ -613,6 +636,34 @@ class _TiledTsxAnimationBrowserState extends State<TiledTsxAnimationBrowser> {
     });
   }
 
+  Map<SurfaceVariantRole, String> _currentRoleAnimationIds() {
+    return <SurfaceVariantRole, String>{
+      for (final entry in _roleControllers.entries)
+        if (entry.value.text.trim().isNotEmpty)
+          entry.key: entry.value.text.trim(),
+    };
+  }
+
+  void _replaceRoleAssignments(Map<SurfaceVariantRole, String> next) {
+    final previous = _currentRoleAnimationIds();
+    setState(() {
+      for (final role in standardSurfaceVariantRoleOrder) {
+        final value = next[role];
+        _roleControllers[role]!.text = value ?? '';
+        if (value == null || value.trim().isEmpty) {
+          _roleSources.remove(role);
+        } else if (previous[role] != value) {
+          _roleSources[role] = const TiledTsxRoleAssignmentMeta(
+            source: TiledTsxRoleAssignmentSource.manual,
+          );
+        }
+      }
+      _presetBuilderErrors = const <String>[];
+      _presetBuilderWarnings = const <String>[];
+      _presetBuilderNote = null;
+    });
+  }
+
   void _createPresetFromBuilder() {
     final sortOrder = int.tryParse(_presetSortOrder.text.trim());
     if (sortOrder == null) {
@@ -693,10 +744,15 @@ class _TiledTsxSurfacePresetBuilderPanel extends StatelessWidget {
     required this.categoryController,
     required this.sortOrderController,
     required this.roleControllers,
+    required this.roleSources,
+    required this.atlas,
+    required this.animations,
+    required this.atlasImageBytes,
     required this.errors,
     required this.warnings,
     required this.note,
     required this.onCreate,
+    required this.onRoleAssignmentsChanged,
     required this.onClose,
   });
 
@@ -706,10 +762,15 @@ class _TiledTsxSurfacePresetBuilderPanel extends StatelessWidget {
   final TextEditingController categoryController;
   final TextEditingController sortOrderController;
   final Map<SurfaceVariantRole, TextEditingController> roleControllers;
+  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Uint8List? atlasImageBytes;
   final List<String> errors;
   final List<String> warnings;
   final String? note;
   final VoidCallback onCreate;
+  final ValueChanged<Map<SurfaceVariantRole, String>> onRoleAssignmentsChanged;
   final VoidCallback onClose;
 
   @override
@@ -840,14 +901,19 @@ class _TiledTsxSurfacePresetBuilderPanel extends StatelessWidget {
                 ),
               ),
               const SizedBox(height: 6),
-              for (final role in standardSurfaceVariantRoleOrder)
-                Padding(
-                  padding: const EdgeInsets.only(bottom: 8),
-                  child: _RoleAnimationField(
-                    role: role,
-                    controller: roleControllers[role]!,
-                  ),
-                ),
+              TiledTsxRoleMappingBuilder(
+                atlas: atlas,
+                animations: animations,
+                selectedAnimationIds: selectedAnimationIds,
+                roleAnimationIds: {
+                  for (final entry in roleControllers.entries)
+                    if (entry.value.text.trim().isNotEmpty)
+                      entry.key: entry.value.text.trim(),
+                },
+                roleSources: roleSources,
+                atlasImageBytes: atlasImageBytes,
+                onChanged: onRoleAssignmentsChanged,
+              ),
               if (errors.isNotEmpty) ...[
                 const SizedBox(height: 4),
                 for (final error in errors)
@@ -940,67 +1006,6 @@ class _BuilderTextField extends StatelessWidget {
   }
 }
 
-class _RoleAnimationField extends StatelessWidget {
-  const _RoleAnimationField({
-    required this.role,
-    required this.controller,
-  });
-
-  final SurfaceVariantRole role;
-  final TextEditingController controller;
-
-  @override
-  Widget build(BuildContext context) {
-    final label = EditorChrome.primaryLabel(context);
-    final subtle = EditorChrome.subtleLabel(context);
-    final roleLabel = role == SurfaceVariantRole.isolated
-        ? 'Plein(center)'
-        : SurfaceStudioRoleLabels.labelForRole(role);
-    return Row(
-      children: [
-        SizedBox(
-          width: 170,
-          child: Text(
-            roleLabel,
-            overflow: TextOverflow.ellipsis,
-            style: TextStyle(
-              color: label,
-              fontSize: 11.5,
-              fontWeight: FontWeight.w700,
-            ),
-          ),
-        ),
-        const SizedBox(width: 8),
-        Expanded(
-          child: CupertinoTextField(
-            key: ValueKey(
-              'tiled_tsx_surface_preset_builder.role.${role.name}',
-            ),
-            controller: controller,
-            placeholder: 'animation id sélectionnée',
-            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
-            style: const TextStyle(fontSize: 12),
-            placeholderStyle: TextStyle(color: subtle, fontSize: 12),
-          ),
-        ),
-        CupertinoButton(
-          minimumSize: Size.zero,
-          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
-          onPressed: () => controller.clear(),
-          child: const Text(
-            'Clear',
-            style: TextStyle(
-              color: _tsxAccent,
-              fontSize: 11,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-        ),
-      ],
-    );
-  }
-}
-
 class _StatusLine extends StatelessWidget {
   const _StatusLine({
     required this.text,
@@ -1038,6 +1043,9 @@ class _TiledTsxMistralGroupingPanel extends StatelessWidget {
     required this.onApplyAll,
     required this.onAccept,
     required this.onReject,
+    required this.atlas,
+    required this.animations,
+    required this.atlasImageBytes,
   });
 
   final TiledTsxMistralGroupingResult? result;
@@ -1049,6 +1057,9 @@ class _TiledTsxMistralGroupingPanel extends StatelessWidget {
   final VoidCallback onApplyAll;
   final ValueChanged<TiledTsxRoleAnimationSuggestion> onAccept;
   final ValueChanged<TiledTsxRoleAnimationSuggestion> onReject;
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Uint8List? atlasImageBytes;
 
   @override
   Widget build(BuildContext context) {
@@ -1163,9 +1174,10 @@ class _TiledTsxMistralGroupingPanel extends StatelessWidget {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
-        if (result.warnings.isNotEmpty) ...[
-          for (final warning in result.warnings)
-            _StatusLine(text: warning, color: const Color(0xFFFACC15)),
+        if (_groupMistralWarnings(result.warnings).hasWarnings) ...[
+          _MistralWarningSummary(
+            groupedWarnings: _groupMistralWarnings(result.warnings),
+          ),
           const SizedBox(height: 6),
         ],
         if (result.suggestions.isEmpty)
@@ -1232,6 +1244,9 @@ class _TiledTsxMistralGroupingPanel extends StatelessWidget {
               suggestion: suggestion,
               label: label,
               subtle: subtle,
+              animation: _animationForSuggestion(suggestion),
+              atlas: atlas,
+              atlasImageBytes: atlasImageBytes,
               onAccept: () => onAccept(suggestion),
               onReject: () => onReject(suggestion),
             ),
@@ -1239,6 +1254,17 @@ class _TiledTsxMistralGroupingPanel extends StatelessWidget {
       ],
     );
   }
+
+  ProjectSurfaceAnimation? _animationForSuggestion(
+    TiledTsxRoleAnimationSuggestion suggestion,
+  ) {
+    for (final animation in animations) {
+      if (animation.id == suggestion.animationId) {
+        return animation;
+      }
+    }
+    return null;
+  }
 }
 
 class _TiledTsxMistralSuggestionRow extends StatelessWidget {
@@ -1246,6 +1272,9 @@ class _TiledTsxMistralSuggestionRow extends StatelessWidget {
     required this.suggestion,
     required this.label,
     required this.subtle,
+    required this.animation,
+    required this.atlas,
+    required this.atlasImageBytes,
     required this.onAccept,
     required this.onReject,
   });
@@ -1253,6 +1282,9 @@ class _TiledTsxMistralSuggestionRow extends StatelessWidget {
   final TiledTsxRoleAnimationSuggestion suggestion;
   final Color label;
   final Color subtle;
+  final ProjectSurfaceAnimation? animation;
+  final ProjectSurfaceAtlas? atlas;
+  final Uint8List? atlasImageBytes;
   final VoidCallback onAccept;
   final VoidCallback onReject;
 
@@ -1274,17 +1306,60 @@ class _TiledTsxMistralSuggestionRow extends StatelessWidget {
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
-          Text(
-            '$roleLabel → ${suggestion.animationId}',
-            style: TextStyle(
-              color: label,
-              fontSize: 12,
-              fontWeight: FontWeight.w800,
-            ),
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              SizedBox(
+                width: 58,
+                height: 58,
+                child: animation == null
+                    ? const _SmallPreviewFallback()
+                    : TiledTsxAnimationTilePreview(
+                        atlas: atlas,
+                        animation: animation!,
+                        atlasImageBytes: atlasImageBytes,
+                        compact: true,
+                      ),
+              ),
+              const SizedBox(width: 10),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      roleLabel,
+                      style: TextStyle(
+                        color: label,
+                        fontSize: 12,
+                        fontWeight: FontWeight.w900,
+                      ),
+                    ),
+                    Text(
+                      suggestion.animationId,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: label,
+                        fontSize: 11.5,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                    const SizedBox(height: 3),
+                    Text(
+                      'Confiance : ${suggestion.confidence.name}',
+                      style: TextStyle(
+                        color: subtle,
+                        fontSize: 11.2,
+                        height: 1.3,
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ],
           ),
           const SizedBox(height: 3),
           Text(
-            'confidence ${suggestion.confidence.name} · evidence ${suggestion.evidenceAnimationIds.join(', ')}',
+            'Evidence : ${suggestion.evidenceAnimationIds.join(', ')}',
             style: TextStyle(color: subtle, fontSize: 11.2, height: 1.3),
           ),
           Text(
@@ -1333,6 +1408,137 @@ class _TiledTsxMistralSuggestionRow extends StatelessWidget {
   }
 }
 
+class _SmallPreviewFallback extends StatelessWidget {
+  const _SmallPreviewFallback();
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: const Color(0xFF101820),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
+        ),
+      ),
+      child: const Center(
+        child: Padding(
+          padding: EdgeInsets.all(4),
+          child: Text(
+            'Aperçu indisponible',
+            textAlign: TextAlign.center,
+            style: TextStyle(
+              color: Color(0xFF94A3B8),
+              fontSize: 9,
+              fontWeight: FontWeight.w700,
+              height: 1.1,
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _MistralWarningSummary extends StatelessWidget {
+  const _MistralWarningSummary({required this.groupedWarnings});
+
+  final _GroupedMistralWarnings groupedWarnings;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: const Color(0xFFFACC15).withValues(alpha: 0.10),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: const Color(0xFFFACC15).withValues(alpha: 0.35),
+        ),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          const Text(
+            'Suggestions ignorées',
+            style: TextStyle(
+              color: Color(0xFFFACC15),
+              fontSize: 11.5,
+              fontWeight: FontWeight.w900,
+            ),
+          ),
+          const SizedBox(height: 4),
+          for (final entry in groupedWarnings.duplicateRoleCounts.entries)
+            Text(
+              '${entry.value} suggestions ont été ignorées car elles proposaient déjà ${_mistralRoleLabel(entry.key)}.',
+              style: const TextStyle(
+                color: Color(0xFFFACC15),
+                fontSize: 11.5,
+                fontWeight: FontWeight.w700,
+                height: 1.3,
+              ),
+            ),
+          for (final warning in groupedWarnings.otherWarnings)
+            Text(
+              warning,
+              style: const TextStyle(
+                color: Color(0xFFFACC15),
+                fontSize: 11.5,
+                fontWeight: FontWeight.w700,
+                height: 1.3,
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+final class _GroupedMistralWarnings {
+  const _GroupedMistralWarnings({
+    required this.duplicateRoleCounts,
+    required this.otherWarnings,
+  });
+
+  final Map<String, int> duplicateRoleCounts;
+  final List<String> otherWarnings;
+
+  bool get hasWarnings =>
+      duplicateRoleCounts.isNotEmpty || otherWarnings.isNotEmpty;
+}
+
+_GroupedMistralWarnings _groupMistralWarnings(List<String> warnings) {
+  final duplicateRoleCounts = <String, int>{};
+  final otherWarnings = <String>[];
+  final duplicateRoleRegex =
+      RegExp(r'^Rôle Mistral dupliqué rejeté : ([A-Za-z0-9_]+)\.$');
+  for (final warning in warnings) {
+    final match = duplicateRoleRegex.firstMatch(warning);
+    if (match == null) {
+      otherWarnings.add(warning);
+      continue;
+    }
+    final roleName = match.group(1)!;
+    duplicateRoleCounts[roleName] = (duplicateRoleCounts[roleName] ?? 0) + 1;
+  }
+  return _GroupedMistralWarnings(
+    duplicateRoleCounts: Map<String, int>.unmodifiable(duplicateRoleCounts),
+    otherWarnings: List<String>.unmodifiable(otherWarnings),
+  );
+}
+
+String _mistralRoleLabel(String roleName) {
+  for (final role in standardSurfaceVariantRoleOrder) {
+    if (role.name == roleName) {
+      if (role == SurfaceVariantRole.isolated) {
+        return 'Plein(center)';
+      }
+      return SurfaceStudioRoleLabels.labelForRole(role);
+    }
+  }
+  return roleName;
+}
+
 class TiledTsxSurfaceAnimationPreview extends StatefulWidget {
   const TiledTsxSurfaceAnimationPreview({
     super.key,
```

#### git diff -- packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart b/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
index 801d7e05..a44a4429 100644
--- a/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
+++ b/packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
@@ -72,12 +72,27 @@ void main() {
         find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.name')),
         'Water TSX Surface',
       );
-      await tester.enterText(
+      expect(
         find.byKey(
           const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
         ),
-        'tech-animations-tile-99',
+        findsNothing,
+      );
+
+      final pickIsolated = find.byKey(
+        const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
+      );
+      await tester.ensureVisible(pickIsolated);
+      await tester.tap(pickIsolated);
+      await tester.pumpAndSettle();
+
+      final tile99Option = find.byKey(
+        const ValueKey(
+          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
+        ),
       );
+      await tester.ensureVisible(tile99Option);
+      await tester.tap(tile99Option);
       await tester.pumpAndSettle();
 
       await tester.ensureVisible(createPreset);
```

#### git diff -- packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart b/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
index 2e552189..a46e6f59 100644
--- a/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
+++ b/packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
@@ -165,9 +165,20 @@ void main() {
         findsOneWidget,
       );
       expect(
-        find.widgetWithText(CupertinoTextField, 'tech-animations-tile-99'),
+        find.byKey(
+          const ValueKey('tiled_tsx_role_mapping_builder.slot.isolated'),
+        ),
         findsOneWidget,
       );
+      expect(find.text('Plein(center)'), findsWidgets);
+      expect(find.text('Source : Mistral'), findsOneWidget);
+      expect(find.text('Aperçu indisponible'), findsWidgets);
+      expect(
+        find.byKey(
+          const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
+        ),
+        findsNothing,
+      );
       expect(changedCatalog, isNull);
       expect(find.text('Créer le preset'), findsOneWidget);
     },
```


### Fichiers ajoutés

#### packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart

```diff
+++ packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' show BoxDecoration, CustomPaint, InkWell;
+import 'package:map_core/map_core.dart';
+
+import '../../../ui/shared/cupertino_editor_widgets.dart';
+import '../surface_studio_mapping_suggestion_models.dart';
+import '../surface_studio_vertical_atlas_role_mapping.dart';
+import 'tiled_tsx_animation_browser_models.dart';
+
+const Color _tsxRoleAccent = Color(0xFF2DD4BF);
+
+enum TiledTsxRoleAssignmentSource {
+  manual,
+  mistral,
+}
+
+final class TiledTsxRoleAssignmentMeta {
+  const TiledTsxRoleAssignmentMeta({
+    required this.source,
+    this.confidence,
+  });
+
+  final TiledTsxRoleAssignmentSource source;
+  final SurfaceStudioMappingSuggestionConfidence? confidence;
+}
+
+class TiledTsxRoleMappingBuilder extends StatefulWidget {
+  const TiledTsxRoleMappingBuilder({
+    super.key,
+    required this.atlas,
+    required this.animations,
+    required this.selectedAnimationIds,
+    required this.roleAnimationIds,
+    required this.roleSources,
+    required this.onChanged,
+    this.atlasImageBytes,
+  });
+
+  final ProjectSurfaceAtlas? atlas;
+  final List<ProjectSurfaceAnimation> animations;
+  final Set<String> selectedAnimationIds;
+  final Map<SurfaceVariantRole, String> roleAnimationIds;
+  final Map<SurfaceVariantRole, TiledTsxRoleAssignmentMeta> roleSources;
+  final Uint8List? atlasImageBytes;
+  final ValueChanged<Map<SurfaceVariantRole, String>> onChanged;
+
+  @override
+  State<TiledTsxRoleMappingBuilder> createState() =>
+      _TiledTsxRoleMappingBuilderState();
+}
+
+class _TiledTsxRoleMappingBuilderState
+    extends State<TiledTsxRoleMappingBuilder> {
+  final TextEditingController _query = TextEditingController();
+  SurfaceVariantRole? _pickerRole;
+
+  @override
+  void dispose() {
+    _query.dispose();
+    super.dispose();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final selectedAnimations = _selectedAnimations();
+    final usedIds = widget.roleAnimationIds.values
+        .where((id) => id.trim().isNotEmpty)
+        .toSet();
+    final remainingCount =
+        widget.selectedAnimationIds.where((id) => !usedIds.contains(id)).length;
+    return Container(
+      key: const ValueKey('tiled_tsx_role_mapping_builder.root'),
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.5),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
+        ),
+      ),
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            Text(
+              'Mapping visuel rôle → animation',
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Text(
+              'Choisissez une animation visuellement pour chaque rôle. Aucun ID n’a besoin d’être saisi à la main.',
+              style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
+            ),
+            const SizedBox(height: 8),
+            Wrap(
+              spacing: 8,
+              runSpacing: 6,
+              children: [
+                _SummaryPill(
+                  'Animations sélectionnées : ${widget.selectedAnimationIds.length}',
+                ),
+                _SummaryPill('Utilisées : ${usedIds.length}'),
+                _SummaryPill('Restantes : $remainingCount'),
+              ],
+            ),
+            const SizedBox(height: 10),
+            _SurfacePreviewSummary(
+              roleAnimationIds: widget.roleAnimationIds,
+            ),
+            if (_pickerRole != null) ...[
+              const SizedBox(height: 8),
+              _AnimationPicker(
+                role: _pickerRole!,
+                animations: selectedAnimations,
+                query: _query,
+                atlas: widget.atlas,
+                atlasImageBytes: widget.atlasImageBytes,
+                onQueryChanged: () => setState(() {}),
+                onCancel: () => setState(() => _pickerRole = null),
+                onSelected: (animationId) =>
+                    _assignRole(_pickerRole!, animationId),
+              ),
+            ],
+            const SizedBox(height: 12),
+            for (final group in _roleGroups) ...[
+              _RoleGroupHeader(title: group.title),
+              const SizedBox(height: 6),
+              for (final role in group.roles)
+                Padding(
+                  padding: const EdgeInsets.only(bottom: 8),
+                  child: _RoleMappingSlot(
+                    role: role,
+                    animation: _animationForRole(role),
+                    animationItem: _itemForRole(role),
+                    source: widget.roleSources[role],
+                    atlas: widget.atlas,
+                    atlasImageBytes: widget.atlasImageBytes,
+                    onPick: () {
+                      setState(() {
+                        _pickerRole = role;
+                        _query.clear();
+                      });
+                    },
+                    onClear: widget.roleAnimationIds.containsKey(role)
+                        ? () => _clearRole(role)
+                        : null,
+                  ),
+                ),
+            ],
+          ],
+        ),
+      ),
+    );
+  }
+
+  List<ProjectSurfaceAnimation> _selectedAnimations() {
+    return widget.animations
+        .where(
+            (animation) => widget.selectedAnimationIds.contains(animation.id))
+        .toList(growable: false);
+  }
+
+  ProjectSurfaceAnimation? _animationForRole(SurfaceVariantRole role) {
+    final id = widget.roleAnimationIds[role];
+    if (id == null) {
+      return null;
+    }
+    for (final animation in widget.animations) {
+      if (animation.id == id) {
+        return animation;
+      }
+    }
+    return null;
+  }
+
+  TiledTsxAnimationBrowserItem? _itemForRole(SurfaceVariantRole role) {
+    final animation = _animationForRole(role);
+    if (animation == null) {
+      return null;
+    }
+    return buildTiledTsxAnimationBrowserItems(animations: [animation]).single;
+  }
+
+  void _assignRole(SurfaceVariantRole role, String animationId) {
+    final next = Map<SurfaceVariantRole, String>.of(widget.roleAnimationIds);
+    next[role] = animationId;
+    widget.onChanged(Map<SurfaceVariantRole, String>.unmodifiable(next));
+    setState(() => _pickerRole = null);
+  }
+
+  void _clearRole(SurfaceVariantRole role) {
+    final next = Map<SurfaceVariantRole, String>.of(widget.roleAnimationIds)
+      ..remove(role);
+    widget.onChanged(Map<SurfaceVariantRole, String>.unmodifiable(next));
+  }
+}
+
+class _SurfacePreviewSummary extends StatelessWidget {
+  const _SurfacePreviewSummary({required this.roleAnimationIds});
+
+  final Map<SurfaceVariantRole, String> roleAnimationIds;
+
+  @override
+  Widget build(BuildContext context) {
+    final hasCenter = roleAnimationIds.containsKey(SurfaceVariantRole.isolated);
+    final mappedCount = roleAnimationIds.length;
+    final missingCount = standardSurfaceVariantRoleOrder.length - mappedCount;
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: hasCenter
+            ? _tsxRoleAccent.withValues(alpha: 0.10)
+            : const Color(0xFFFACC15).withValues(alpha: 0.10),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: hasCenter
+              ? _tsxRoleAccent.withValues(alpha: 0.30)
+              : const Color(0xFFFACC15).withValues(alpha: 0.35),
+        ),
+      ),
+      child: Text(
+        hasCenter
+            ? 'Aperçu de la surface : preview partielle active. $mappedCount rôles utilisés, $missingCount rôles encore vides.'
+            : 'Aperçu de la surface : Plein(center) obligatoire.',
+        style: TextStyle(
+          color: EditorChrome.primaryLabel(context),
+          fontSize: 11.5,
+          fontWeight: FontWeight.w700,
+          height: 1.35,
+        ),
+      ),
+    );
+  }
+}
+
+class _AnimationPicker extends StatelessWidget {
+  const _AnimationPicker({
+    required this.role,
+    required this.animations,
+    required this.query,
+    required this.atlas,
+    required this.atlasImageBytes,
+    required this.onQueryChanged,
+    required this.onCancel,
+    required this.onSelected,
+  });
+
+  final SurfaceVariantRole role;
+  final List<ProjectSurfaceAnimation> animations;
+  final TextEditingController query;
+  final ProjectSurfaceAtlas? atlas;
+  final Uint8List? atlasImageBytes;
+  final VoidCallback onQueryChanged;
+  final VoidCallback onCancel;
+  final ValueChanged<String> onSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final roleLabel = _labelForRole(role);
+    final q = query.text.trim().toLowerCase();
+    final visible = animations.where((animation) {
+      if (q.isEmpty) {
+        return true;
+      }
+      return animation.id.toLowerCase().contains(q) ||
+          animation.name.toLowerCase().contains(q);
+    }).toList(growable: false);
+    return Container(
+      key: ValueKey('tiled_tsx_role_mapping_builder.picker.${role.name}'),
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: _tsxRoleAccent.withValues(alpha: 0.35)),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              Expanded(
+                child: Text(
+                  'Choisir une animation pour $roleLabel',
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 12.5,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+              CupertinoButton(
+                minimumSize: Size.zero,
+                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
+                onPressed: onCancel,
+                child: const Text(
+                  'Fermer',
+                  style: TextStyle(
+                    color: _tsxRoleAccent,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 8),
+          CupertinoTextField(
+            key: ValueKey('tiled_tsx_role_mapping_builder.search.${role.name}'),
+            controller: query,
+            placeholder: 'Rechercher une animation…',
+            onChanged: (_) => onQueryChanged(),
+            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
+            decoration: BoxDecoration(
+              color: const Color(0xFF0F172A).withValues(alpha: 0.45),
+              borderRadius: BorderRadius.circular(8),
+              border: Border.all(
+                color: EditorChrome.editorIslandRim(context)
+                    .withValues(alpha: 0.7),
+              ),
+            ),
+            style: TextStyle(color: label, fontSize: 12),
+            placeholderStyle: TextStyle(color: subtle, fontSize: 12),
+          ),
+          const SizedBox(height: 8),
+          if (visible.isEmpty)
+            Text(
+              'Aucune animation sélectionnée ne correspond.',
+              style: TextStyle(color: subtle, fontSize: 11.5),
+            )
+          else
+            ConstrainedBox(
+              constraints: const BoxConstraints(maxHeight: 280),
+              child: SingleChildScrollView(
+                child: Column(
+                  children: [
+                    for (final animation in visible)
+                      _AnimationPickerOption(
+                        role: role,
+                        animation: animation,
+                        atlas: atlas,
+                        atlasImageBytes: atlasImageBytes,
+                        onSelected: () => onSelected(animation.id),
+                      ),
+                  ],
+                ),
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+class _AnimationPickerOption extends StatelessWidget {
+  const _AnimationPickerOption({
+    required this.role,
+    required this.animation,
+    required this.atlas,
+    required this.atlasImageBytes,
+    required this.onSelected,
+  });
+
+  final SurfaceVariantRole role;
+  final ProjectSurfaceAnimation animation;
+  final ProjectSurfaceAtlas? atlas;
+  final Uint8List? atlasImageBytes;
+  final VoidCallback onSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final item =
+        buildTiledTsxAnimationBrowserItems(animations: [animation]).single;
+    final subtle = EditorChrome.subtleLabel(context);
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 6),
+      child: InkWell(
+        key: ValueKey(
+          'tiled_tsx_role_mapping_builder.option.${role.name}.${animation.id}',
+        ),
+        onTap: onSelected,
+        borderRadius: BorderRadius.circular(10),
+        child: Container(
+          padding: const EdgeInsets.all(8),
+          decoration: BoxDecoration(
+            color: EditorChrome.islandFillElevated(context),
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(
+              color:
+                  EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
+            ),
+          ),
+          child: Row(
+            children: [
+              SizedBox(
+                width: 50,
+                height: 50,
+                child: TiledTsxAnimationTilePreview(
+                  atlas: atlas,
+                  animation: animation,
+                  atlasImageBytes: atlasImageBytes,
+                  compact: true,
+                ),
+              ),
+              const SizedBox(width: 10),
+              Expanded(
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      animation.id,
+                      overflow: TextOverflow.ellipsis,
+                      style: TextStyle(
+                        color: EditorChrome.primaryLabel(context),
+                        fontSize: 12,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                    Text(
+                      '${_frameCountLabel(animation)} · base tile ${item.baseTileId}',
+                      style: TextStyle(
+                        color: subtle,
+                        fontSize: 11,
+                        height: 1.3,
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _RoleMappingSlot extends StatelessWidget {
+  const _RoleMappingSlot({
+    required this.role,
+    required this.animation,
+    required this.animationItem,
+    required this.source,
+    required this.atlas,
+    required this.atlasImageBytes,
+    required this.onPick,
+    required this.onClear,
+  });
+
+  final SurfaceVariantRole role;
+  final ProjectSurfaceAnimation? animation;
+  final TiledTsxAnimationBrowserItem? animationItem;
+  final TiledTsxRoleAssignmentMeta? source;
+  final ProjectSurfaceAtlas? atlas;
+  final Uint8List? atlasImageBytes;
+  final VoidCallback onPick;
+  final VoidCallback? onClear;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    final assigned = animation != null;
+    return Container(
+      key: ValueKey('tiled_tsx_role_mapping_builder.slot.${role.name}'),
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: assigned
+              ? _tsxRoleAccent.withValues(alpha: 0.34)
+              : EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
+        ),
+      ),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          SizedBox(
+            width: 168,
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  _labelForRole(role),
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 12,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 2),
+                Text(
+                  role.name,
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(color: subtle, fontSize: 10.5),
+                ),
+                const SizedBox(height: 4),
+                Text(
+                  _descriptionForRole(role),
+                  style: TextStyle(color: subtle, fontSize: 10.8, height: 1.25),
+                ),
+              ],
+            ),
+          ),
+          const SizedBox(width: 10),
+          SizedBox(
+            width: 66,
+            height: 66,
+            child: animation == null
+                ? const _EmptyPreviewBox()
+                : TiledTsxAnimationTilePreview(
+                    atlas: atlas,
+                    animation: animation!,
+                    atlasImageBytes: atlasImageBytes,
+                  ),
+          ),
+          const SizedBox(width: 10),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  animation?.id ?? 'Non assigné',
+                  overflow: TextOverflow.ellipsis,
+                  style: TextStyle(
+                    color: assigned ? label : subtle,
+                    fontSize: 12,
+                    fontWeight: assigned ? FontWeight.w800 : FontWeight.w700,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                if (animation != null)
+                  Text(
+                    '${_frameCountLabel(animation!)} · ${animation!.totalDurationMs} ms',
+                    style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
+                  ),
+                if (animation != null)
+                  Text(
+                    'base tile ${animationItem?.baseTileId ?? '—'}',
+                    style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
+                  ),
+                if (source != null) ...[
+                  const SizedBox(height: 3),
+                  Text(
+                    source!.source == TiledTsxRoleAssignmentSource.mistral
+                        ? 'Source : Mistral'
+                        : 'Source : Manuel',
+                    style: const TextStyle(
+                      color: _tsxRoleAccent,
+                      fontSize: 10.8,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  if (source!.confidence != null)
+                    Text(
+                      'Confiance : ${source!.confidence!.name}',
+                      style: const TextStyle(
+                        color: _tsxRoleAccent,
+                        fontSize: 10.8,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                ],
+                const SizedBox(height: 6),
+                Wrap(
+                  spacing: 6,
+                  runSpacing: 4,
+                  children: [
+                    CupertinoButton(
+                      key: ValueKey(
+                        'tiled_tsx_role_mapping_builder.pick.${role.name}',
+                      ),
+                      minimumSize: Size.zero,
+                      padding: const EdgeInsets.symmetric(
+                        horizontal: 8,
+                        vertical: 5,
+                      ),
+                      onPressed: onPick,
+                      child: Text(
+                        assigned ? 'Changer' : 'Choisir une animation',
+                        style: const TextStyle(
+                          color: _tsxRoleAccent,
+                          fontSize: 11,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                    ),
+                    if (assigned)
+                      CupertinoButton(
+                        key: ValueKey(
+                          'tiled_tsx_role_mapping_builder.clear.${role.name}',
+                        ),
+                        minimumSize: Size.zero,
+                        padding: const EdgeInsets.symmetric(
+                          horizontal: 8,
+                          vertical: 5,
+                        ),
+                        onPressed: onClear,
+                        child: const Text(
+                          'Clear',
+                          style: TextStyle(
+                            color: _tsxRoleAccent,
+                            fontSize: 11,
+                            fontWeight: FontWeight.w800,
+                          ),
+                        ),
+                      ),
+                  ],
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class TiledTsxAnimationTilePreview extends StatefulWidget {
+  const TiledTsxAnimationTilePreview({
+    super.key,
+    required this.atlas,
+    required this.animation,
+    this.atlasImageBytes,
+    this.compact = false,
+  });
+
+  final ProjectSurfaceAtlas? atlas;
+  final ProjectSurfaceAnimation animation;
+  final Uint8List? atlasImageBytes;
+  final bool compact;
+
+  @override
+  State<TiledTsxAnimationTilePreview> createState() =>
+      _TiledTsxAnimationTilePreviewState();
+}
+
+class _TiledTsxAnimationTilePreviewState
+    extends State<TiledTsxAnimationTilePreview> {
+  ui.Image? _decoded;
+  Uint8List? _decodedBytes;
+
+  @override
+  void initState() {
+    super.initState();
+    _decodeImage();
+  }
+
+  @override
+  void didUpdateWidget(covariant TiledTsxAnimationTilePreview oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (widget.atlasImageBytes != oldWidget.atlasImageBytes) {
+      _decodeImage();
+    }
+  }
+
+  @override
+  void dispose() {
+    _decoded?.dispose();
+    super.dispose();
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final atlas = widget.atlas;
+    final decoded = _decoded;
+    final frames = widget.animation.timeline.frames;
+    if (atlas == null ||
+        decoded == null ||
+        widget.atlasImageBytes == null ||
+        frames.isEmpty) {
+      return const _FallbackPreviewBox(text: 'Aperçu indisponible');
+    }
+    final frame = frames.first;
+    final tileWidth = atlas.geometry.tileSize.width;
+    final tileHeight = atlas.geometry.tileSize.height;
+    final source = Rect.fromLTWH(
+      (frame.tileRef.column * tileWidth).toDouble(),
+      (frame.tileRef.row * tileHeight).toDouble(),
+      tileWidth.toDouble(),
+      tileHeight.toDouble(),
+    );
+    return ClipRRect(
+      borderRadius: BorderRadius.circular(8),
+      child: CustomPaint(
+        painter: _TilePreviewPainter(image: decoded, source: source),
+        child: const SizedBox.expand(),
+      ),
+    );
+  }
+
+  void _decodeImage() {
+    final bytes = widget.atlasImageBytes;
+    if (bytes == null || bytes.isEmpty) {
+      _decodedBytes = null;
+      _decoded?.dispose();
+      _decoded = null;
+      return;
+    }
+    if (identical(bytes, _decodedBytes)) {
+      return;
+    }
+    _decodedBytes = bytes;
+    ui.decodeImageFromList(bytes, (image) {
+      if (!mounted) {
+        image.dispose();
+        return;
+      }
+      setState(() {
+        _decoded?.dispose();
+        _decoded = image;
+      });
+    });
+  }
+}
+
+class _TilePreviewPainter extends CustomPainter {
+  const _TilePreviewPainter({
+    required this.image,
+    required this.source,
+  });
+
+  final ui.Image image;
+  final Rect source;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final destination = Offset.zero & size;
+    final paint = Paint()
+      ..filterQuality = FilterQuality.none
+      ..isAntiAlias = false;
+    canvas.drawImageRect(image, source, destination, paint);
+  }
+
+  @override
+  bool shouldRepaint(covariant _TilePreviewPainter oldDelegate) {
+    return oldDelegate.image != image || oldDelegate.source != source;
+  }
+}
+
+class _EmptyPreviewBox extends StatelessWidget {
+  const _EmptyPreviewBox();
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: const Color(0xFF0F172A).withValues(alpha: 0.56),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
+        ),
+      ),
+      child: const Center(
+        child: Text(
+          'Vide',
+          style: TextStyle(
+            color: Color(0xFF94A3B8),
+            fontSize: 10.5,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _FallbackPreviewBox extends StatelessWidget {
+  const _FallbackPreviewBox({required this.text});
+
+  final String text;
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: const Color(0xFF101820),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.7),
+        ),
+      ),
+      child: Center(
+        child: Padding(
+          padding: const EdgeInsets.all(6),
+          child: Text(
+            text,
+            textAlign: TextAlign.center,
+            style: const TextStyle(
+              color: Color(0xFF94A3B8),
+              fontSize: 9.8,
+              fontWeight: FontWeight.w700,
+              height: 1.15,
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _RoleGroupHeader extends StatelessWidget {
+  const _RoleGroupHeader({required this.title});
+
+  final String title;
+
+  @override
+  Widget build(BuildContext context) {
+    return Text(
+      title,
+      style: TextStyle(
+        color: EditorChrome.primaryLabel(context),
+        fontSize: 12.5,
+        fontWeight: FontWeight.w900,
+      ),
+    );
+  }
+}
+
+class _SummaryPill extends StatelessWidget {
+  const _SummaryPill(this.label);
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: _tsxRoleAccent.withValues(alpha: 0.10),
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(color: _tsxRoleAccent.withValues(alpha: 0.25)),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+        child: Text(
+          label,
+          style: const TextStyle(
+            color: _tsxRoleAccent,
+            fontSize: 10.5,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+final class _RoleGroup {
+  const _RoleGroup({
+    required this.title,
+    required this.roles,
+  });
+
+  final String title;
+  final List<SurfaceVariantRole> roles;
+}
+
+const _roleGroups = <_RoleGroup>[
+  _RoleGroup(
+    title: 'Surface principale',
+    roles: [
+      SurfaceVariantRole.isolated,
+      SurfaceVariantRole.horizontal,
+      SurfaceVariantRole.vertical,
+    ],
+  ),
+  _RoleGroup(
+    title: 'Bords',
+    roles: [
+      SurfaceVariantRole.endNorth,
+      SurfaceVariantRole.endEast,
+      SurfaceVariantRole.endSouth,
+      SurfaceVariantRole.endWest,
+    ],
+  ),
+  _RoleGroup(
+    title: 'Coins externes',
+    roles: [
+      SurfaceVariantRole.cornerNW,
+      SurfaceVariantRole.cornerNE,
+      SurfaceVariantRole.cornerSW,
+      SurfaceVariantRole.cornerSE,
+    ],
+  ),
+  _RoleGroup(
+    title: 'Coins internes',
+    roles: [
+      SurfaceVariantRole.innerCornerNW,
+      SurfaceVariantRole.innerCornerNE,
+      SurfaceVariantRole.innerCornerSW,
+      SurfaceVariantRole.innerCornerSE,
+    ],
+  ),
+  _RoleGroup(
+    title: 'Jonctions',
+    roles: [
+      SurfaceVariantRole.teeNorth,
+      SurfaceVariantRole.teeEast,
+      SurfaceVariantRole.teeSouth,
+      SurfaceVariantRole.teeWest,
+      SurfaceVariantRole.cross,
+    ],
+  ),
+];
+
+String _labelForRole(SurfaceVariantRole role) {
+  if (role == SurfaceVariantRole.isolated) {
+    return 'Plein(center)';
+  }
+  return SurfaceStudioRoleLabels.labelForRole(role);
+}
+
+String _descriptionForRole(SurfaceVariantRole role) {
+  return switch (role) {
+    SurfaceVariantRole.isolated => 'Surface intérieure répétable.',
+    SurfaceVariantRole.horizontal => 'Transition horizontale.',
+    SurfaceVariantRole.vertical => 'Transition verticale.',
+    SurfaceVariantRole.endNorth => 'Bord supérieur d’une surface.',
+    SurfaceVariantRole.endEast => 'Bord droit d’une surface.',
+    SurfaceVariantRole.endSouth => 'Bord inférieur d’une surface.',
+    SurfaceVariantRole.endWest => 'Bord gauche d’une surface.',
+    SurfaceVariantRole.cornerNW => 'Coin externe haut gauche.',
+    SurfaceVariantRole.cornerNE => 'Coin externe haut droit.',
+    SurfaceVariantRole.cornerSW => 'Coin externe bas gauche.',
+    SurfaceVariantRole.cornerSE => 'Coin externe bas droit.',
+    SurfaceVariantRole.innerCornerNW => 'Coin intérieur haut gauche.',
+    SurfaceVariantRole.innerCornerNE => 'Coin intérieur haut droit.',
+    SurfaceVariantRole.innerCornerSW => 'Coin intérieur bas gauche.',
+    SurfaceVariantRole.innerCornerSE => 'Coin intérieur bas droit.',
+    SurfaceVariantRole.teeNorth => 'Jonction en T vers le haut.',
+    SurfaceVariantRole.teeEast => 'Jonction en T vers la droite.',
+    SurfaceVariantRole.teeSouth => 'Jonction en T vers le bas.',
+    SurfaceVariantRole.teeWest => 'Jonction en T vers la gauche.',
+    SurfaceVariantRole.cross => 'Jonction en croix.',
+  };
+}
+
+String _frameCountLabel(ProjectSurfaceAnimation animation) {
+  final count = animation.frameCount;
+  return count == 1 ? '1 frame' : '$count frames';
+}
```

#### packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart

```diff
+++ packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart';
+
+void main() {
+  testWidgets('shows visual role slots and maps roles through a picker',
+      (tester) async {
+    Map<SurfaceVariantRole, String>? changed;
+
+    await tester.pumpWidget(
+      _wrap(
+        TiledTsxRoleMappingBuilder(
+          atlas: _atlas(),
+          animations: _animations(),
+          selectedAnimationIds: const {
+            'tech-animations-tile-99',
+            'tech-animations-tile-105',
+          },
+          roleAnimationIds: const {
+            SurfaceVariantRole.horizontal: 'tech-animations-tile-105',
+          },
+          roleSources: const <SurfaceVariantRole, TiledTsxRoleAssignmentMeta>{},
+          onChanged: (next) => changed = next,
+        ),
+      ),
+    );
+
+    expect(find.text('Surface principale'), findsOneWidget);
+    expect(find.text('Bords'), findsOneWidget);
+    expect(find.text('Coins externes'), findsOneWidget);
+    expect(find.text('Coins internes'), findsOneWidget);
+    expect(find.text('Jonctions'), findsOneWidget);
+    expect(find.text('Plein(center)'), findsOneWidget);
+    expect(find.text('Horizontal'), findsOneWidget);
+    expect(find.text('Vertical'), findsOneWidget);
+    expect(find.text('Bord haut'), findsOneWidget);
+    expect(find.text('Coin haut gauche'), findsOneWidget);
+    expect(find.text('Croix'), findsOneWidget);
+    expect(find.text('Non assigné'), findsWidgets);
+    expect(find.text('tech-animations-tile-105'), findsWidgets);
+    expect(find.text('1 frame · 100 ms'), findsWidgets);
+    expect(find.text('Aperçu indisponible'), findsWidgets);
+    expect(
+      find.byKey(
+        const ValueKey('tiled_tsx_surface_preset_builder.role.isolated'),
+      ),
+      findsNothing,
+    );
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey('tiled_tsx_role_mapping_builder.pick.isolated'),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Choisir une animation pour Plein(center)'), findsOne);
+    await tester.enterText(
+      find.byKey(
+        const ValueKey('tiled_tsx_role_mapping_builder.search.isolated'),
+      ),
+      '99',
+    );
+    await tester.pumpAndSettle();
+    expect(find.text('tech-animations-tile-99'), findsWidgets);
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey(
+          'tiled_tsx_role_mapping_builder.option.isolated.tech-animations-tile-99',
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(changed, isNotNull);
+    expect(changed![SurfaceVariantRole.isolated], 'tech-animations-tile-99');
+    expect(changed![SurfaceVariantRole.horizontal], 'tech-animations-tile-105');
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey('tiled_tsx_role_mapping_builder.clear.horizontal'),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(changed, isNotNull);
+    expect(changed!.containsKey(SurfaceVariantRole.horizontal), isFalse);
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: SizedBox(width: 1200, height: 900, child: child),
+    ),
+  );
+}
+
+ProjectSurfaceAtlas _atlas() {
+  return ProjectSurfaceAtlas(
+    id: 'tech-animations',
+    name: 'TECH-Animations',
+    tilesetId: 'tech-nature-animations',
+    geometry: SurfaceAtlasGeometry(
+      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+      gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
+      layout: SurfaceAtlasLayout.grid,
+    ),
+  );
+}
+
+List<ProjectSurfaceAnimation> _animations() {
+  return [
+    _animation('tech-animations-tile-99', 1, 1),
+    _animation('tech-animations-tile-105', 7, 1),
+  ];
+}
+
+ProjectSurfaceAnimation _animation(String id, int column, int row) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: id,
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'tech-animations',
+            column: column,
+            row: row,
+          ),
+          durationMs: 100,
+        ),
+      ],
+    ),
+  );
+}
```

#### packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart

```diff
+++ packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
+import 'dart:async';
+import 'dart:typed_data';
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
+import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
+
+void main() {
+  testWidgets('Mistral review shows visual suggestions and grouped duplicates',
+      (tester) async {
+    final catalog = _miniCatalog();
+    ProjectSurfaceCatalog? changedCatalog;
+
+    await tester.pumpWidget(
+      _wrap(
+        TiledTsxAnimationBrowser(
+          atlas: catalog.atlases.single,
+          animations: catalog.animations,
+          catalog: catalog,
+          projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
+          groupingSuggester: _DuplicateWarningGroupingSuggester(),
+          onSurfaceCatalogChanged: (next) => changedCatalog = next,
+        ),
+      ),
+    );
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey(
+          'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99',
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    final aiButton = find.byKey(
+      const ValueKey('tiled_tsx_animation_browser.mistral_grouping'),
+    );
+    await tester.ensureVisible(aiButton);
+    await tester.tap(aiButton);
+    await tester.pumpAndSettle();
+    await tester.tap(
+      find.byKey(const ValueKey('tiled_tsx_mistral_grouping.confirm')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Suggestions Mistral'), findsOneWidget);
+    expect(find.text('Plein(center)'), findsWidgets);
+    expect(find.text('tech-animations-tile-99'), findsWidgets);
+    expect(find.text('Confiance : high'), findsOneWidget);
+    expect(find.text('Aperçu indisponible'), findsWidgets);
+    expect(find.text('Suggestions ignorées'), findsOneWidget);
+    expect(
+      find.text(
+        '4 suggestions ont été ignorées car elles proposaient déjà Plein(center).',
+      ),
+      findsOneWidget,
+    );
+    expect(
+      find.text('Rôle Mistral dupliqué rejeté : isolated.'),
+      findsNothing,
+    );
+    expect(changedCatalog, isNull);
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey('tiled_tsx_mistral_grouping.accept.isolated'),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const ValueKey('tiled_tsx_surface_preset_builder.panel')),
+      findsOneWidget,
+    );
+    expect(find.text('Source : Mistral'), findsOneWidget);
+    expect(find.text('Créer le preset'), findsOneWidget);
+    expect(changedCatalog, isNull);
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: Center(
+        child: SizedBox(width: 1100, height: 920, child: child),
+      ),
+    ),
+  );
+}
+
+final class _DuplicateWarningGroupingSuggester
+    implements TiledTsxAnimationGroupingSuggester {
+  @override
+  Future<TiledTsxMistralGroupingResult> suggest({
+    required String apiKey,
+    required TiledTsxMistralGroupingRequest request,
+    required Uint8List? atlasImageBytes,
+  }) async {
+    return const TiledTsxMistralGroupingResult(
+      suggestions: <TiledTsxRoleAnimationSuggestion>[
+        TiledTsxRoleAnimationSuggestion(
+          role: SurfaceVariantRole.isolated,
+          animationId: 'tech-animations-tile-99',
+          confidence: SurfaceStudioMappingSuggestionConfidence.high,
+          reason: 'Full repeatable water tile.',
+          evidenceAnimationIds: <String>['tech-animations-tile-99'],
+        ),
+      ],
+      rejectedAnimationIds: <String>[],
+      warnings: <String>[
+        'Rôle Mistral dupliqué rejeté : isolated.',
+        'Rôle Mistral dupliqué rejeté : isolated.',
+        'Rôle Mistral dupliqué rejeté : isolated.',
+        'Rôle Mistral dupliqué rejeté : isolated.',
+      ],
+    );
+  }
+}
+
+ProjectSurfaceCatalog _miniCatalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [
+      ProjectSurfaceAtlas(
+        id: 'tech-animations',
+        name: 'TECH-Animations',
+        tilesetId: 'tech-nature-animations',
+        geometry: SurfaceAtlasGeometry(
+          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+          gridSize: SurfaceAtlasGridSize(columns: 98, rows: 109),
+          layout: SurfaceAtlasLayout.grid,
+        ),
+      ),
+    ],
+    animations: [
+      _animation('tech-animations-tile-99'),
+      _animation('tech-animations-tile-105'),
+    ],
+  );
+}
+
+ProjectSurfaceAnimation _animation(String id) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: id,
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        SurfaceAnimationFrame(
+          tileRef: SurfaceAtlasTileRef(
+            atlasId: 'tech-animations',
+            column: 1,
+            row: 1,
+          ),
+          durationMs: 100,
+        ),
+      ],
+    ),
+  );
+}
```


## 17. Auto-review

- Fonctionnalité réelle : le mapping TSX n'est plus une saisie brute d'id ; les rôles ont des slots visuels et un picker.
- Qualité UX : l'utilisateur voit le rôle, l'animation, un aperçu/fallback, la provenance et la complétude du mapping.
- Qualité Mistral : les suggestions sont reviewables visuellement et les warnings dupliqués sont groupés.
- Qualité données : le draft existant reste la source de vérité ; aucune structure parallèle n'a été ajoutée.
- Risque restant : le builder est V0 et encore dense ; TSX-8 devrait améliorer grouping/régions et sélection non utilisée.


## 18. Git Status Final

Commande exacte :

```bash
git status --short --untracked-files=all
```

Sortie complète :

```text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/macos/Runner/MainFlutterWindow.swift
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
?? packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart
?? packages/map_editor/test/surface_studio/tall_grass_tsx_asset_importer_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_transparent_color_test.dart
?? reports/surface/surface_studio_tiled_tsx_role_mapping_ux_v0.md
```
