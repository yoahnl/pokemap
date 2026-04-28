# Lot 88-bis — Surface Studio Role Mapping Correction / Edit Preset V0

## Résumé exécutif

Lot 88-bis ajoute dans `map_editor` un éditeur de mapping `Rôle Surface -> Animation` pour les surfaces peignables existantes. L'utilisateur peut sélectionner une surface dans le panneau `Surfaces prêtes à peindre`, ouvrir `Modifier le mapping`, voir les rôles standard, voir les animations liées ou manquantes, choisir une animation du catalogue pour un rôle, puis sauvegarder via le flux de catalogue de travail déjà existant.

Aucun modèle `map_core`, JSON, runtime, renderer, resolver runtime ou save flow profond n'a été modifié.

## Périmètre

Inclus :

- Mutation locale du catalogue de travail dans `map_editor`.
- UI `Édition du mapping de surface`.
- Preview conceptuelle 3x3 des rôles principaux.
- Bouton `Modifier le mapping` depuis `Surfaces prêtes à peindre`.
- Tests unitaires/widget ciblés et non-régression Surface Studio / Surface Painter.

Exclus :

- Aucun changement `map_core`.
- Aucun runtime.
- Aucun renderer Flame.
- Aucun changement JSON.
- Aucun changement `ProjectManifest`.
- Aucune refonte globale Surface Studio.

## Gate 0 — Status initial avant modification

Commande :

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main

<git status initial vide>
<git diff --stat initial vide>

935a0036 feat(map_editor): animate surface editor previews
fe03b827 feat(map_editor): render surface atlas tile previews
5814f6e9 feat(map): add surface role resolver preview
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
```

Changements préexistants : aucun.

## Audit presets / role refs

Commandes d'audit exécutées :

```text
rg -n "SurfaceVariantAnimationRefSet|SurfaceVariantAnimationRef|ProjectSurfacePreset|animationIdForRole|refForRole|containsRole|variantAnimations|standardSurfaceVariantRoleOrder" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
rg -n "preset|Preset|surfacePreset|SurfaceStudioPaintableSurfacesPanel|SurfaceStudioSelectionInspector|SurfaceStudioVerticalAtlasPresetGenerator|workCatalog|dirty|onSurfaceCatalogSaveRequested" packages/map_editor/lib packages/map_editor/test
rg -n "DropdownButton|PopupMenuButton|DropdownMenu|SegmentedButton|Radio|ChoiceChip|ListTile|onChanged" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio
```

Fichiers principaux audités :

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

Constats :

- `ProjectSurfacePreset` expose déjà `animationIdForRole`, `refForRole`, `containsRole`.
- `SurfaceVariantAnimationRefSet` impose des rôles uniques et une liste non vide.
- `standardSurfaceVariantRoleOrder` fournit l'ordre standard à utiliser pour stabiliser les refs après édition.
- `ProjectSurfaceCatalog.presetById` et `animationById` suffisent pour lire le catalogue côté editor.
- Aucun helper `copyWith` n'existe sur ces modèles purs ; il faut reconstruire les instances.

## Audit Surface Studio work catalog / dirty state

`SurfaceStudioPanel` possède déjà un catalogue de travail local :

- `_workReadModel`.
- `_hasWorkCatalogChanges => _workReadModel != widget.readModel`.
- `onSurfaceCatalogSaveRequested` reçoit `_workReadModel.catalog`.
- Le dirty strip apparaît dès que `_workReadModel` diffère du read model source.

Le bon point d'insertion est donc la même boucle locale que l'authoring atlas/preset existant :

```text
catalogue source
-> catalogue de travail local
-> buildSurfaceStudioReadModelFromCatalog
-> dirty state
-> save flow existant
```

## Décision UI Role Mapping Editor

L'UI est ajoutée sans popup complexe :

- Le panneau `Surfaces prêtes à peindre` affiche `Modifier le mapping` sur chaque surface peignable quand le catalogue est mutable.
- Cliquer sélectionne le preset et affiche l'éditeur directement dans ce panneau.
- L'éditeur liste tous les rôles de `standardSurfaceVariantRoleOrder`.
- Chaque rôle affiche un libellé humain, son état `Animation liée` ou `Animation manquante`, et un contrôle de sélection d'animation.

Les textes visibles évitent les noms de types internes. Les ids techniques restent secondaires quand ils sont utiles pour identifier une animation.

## Décision mutation locale

La mutation est locale à `map_editor` dans `surface_studio_preset_editor_controller.dart`.

Règles :

- Trouver le preset par id.
- Reconstruire uniquement le preset modifié.
- Remplacer ou ajouter la ref du rôle ciblé.
- Conserver les autres refs.
- Conserver `id`, `name`, `categoryId`, `sortOrder`.
- Stabiliser l'ordre des refs selon `standardSurfaceVariantRoleOrder`.
- Reconstruire `ProjectSurfaceCatalog` sans changer atlases / animations / ordre des presets.
- Ne pas écrire disque.
- Ne pas modifier `ProjectManifest`.

V0 ne propose pas `Aucune animation` afin d'éviter de produire un preset invalide en supprimant la dernière ref.

## Décision preview mapping

Preview V0 :

- Grille 3x3 conceptuelle.
- Coins, bords, centre/plein.
- Badge `Animation liée` / `Animation manquante`.
- Sélection visuelle du rôle courant.
- Les rôles avancés restent listés dans l'éditeur.

La preview n'est pas un rendu final atlas ; elle sert à comprendre le mapping.

## Implémentation UI

Ajouts :

- `SurfaceStudioRoleMappingEditor`
- `SurfaceStudioRoleMappingPreview`
- Bouton `Modifier le mapping` dans `SurfaceStudioPaintableSurfacesPanel`.
- Sélection du preset dans `SurfaceStudioPanel`.
- Branchement `onRoleAnimationChanged` vers la mutation de catalogue de travail.

## Implémentation mutation catalogue

Nouvelle API editor locale :

```dart
ProjectSurfaceCatalog surfaceStudioReplacePresetRoleAnimation({
  required ProjectSurfaceCatalog catalog,
  required String presetId,
  required SurfaceVariantRole role,
  required String animationId,
})
```

Cette API reconstruit le catalogue en mémoire. Elle ne modifie ni manifest, ni disque, ni modèles.

## Fallbacks / limites V0

- Si aucune animation n'existe, l'éditeur affiche `Aucune animation disponible. Générez d’abord les animations depuis l’atlas.`
- Si un rôle n'est pas couvert, il affiche `Animation manquante` et peut recevoir une animation.
- Pas d'option de suppression de ref en V0.
- Pas de preview atlas frame par rôle dans ce lot.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart`
- `packages/map_editor/test/surface_studio/surface_studio_preset_editor_controller_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart`
- `reports/surface/surface_engine_lot_88_bis_surface_studio_role_mapping_editor.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

## Fichiers supprimés

Aucun.

## Tests lancés

```text
cd packages/map_editor && flutter test test/surface_studio/surface_studio_preset_editor_controller_test.dart test/surface_studio/surface_studio_role_mapping_preview_test.dart test/surface_studio/surface_studio_role_mapping_editor_test.dart
```

Résultat :

```text
00:02 +7: All tests passed!
```

```text
cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart --plain-name 88-bis
```

Résultat :

```text
00:02 +1: All tests passed!
```

```text
cd packages/map_editor && flutter test test/surface_studio
```

Résultat :

```text
00:14 +400: All tests passed!
```

```text
cd packages/map_editor && flutter test test/surface_painter
```

Résultat :

```text
00:03 +42: All tests passed!
```

```text
cd packages/map_editor && flutter test test/map_selection_controller_test.dart
```

Résultat :

```text
00:02 +5: All tests passed!
```

## Analyse lancée

```text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart lib/src/features/surface_studio/surface_studio_panel.dart test/surface_studio/surface_studio_preset_editor_controller_test.dart test/surface_studio/surface_studio_role_mapping_preview_test.dart test/surface_studio/surface_studio_role_mapping_editor_test.dart test/surface_studio/surface_studio_panel_test.dart
```

Résultat :

```text
No issues found! (ran in 1.1s)
```

Analyse globale optionnelle `flutter analyze lib test` non lancée : le prompt demandait une analyse ciblée obligatoire des fichiers modifiés/créés, qui est clean.

## Résultats

- L'utilisateur peut modifier `SurfaceVariantRole -> animationId` depuis Surface Studio.
- Le catalogue de travail devient dirty.
- Le save flow existant reste disponible.
- Surface Painter et Surface Studio ne régressent pas.
- `map_core` et `map_runtime` ne sont pas modifiés.

## Evidence Pack

### Test rouge TDD initial

Le premier test contrôleur a échoué comme prévu avant implémentation :

```text
Error when reading 'lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart': No such file or directory
Method not found: 'surfaceStudioReplacePresetRoleAnimation'
```

### Correction debugging

Le test d'intégration a révélé que `DropdownButton` nécessitait un ancêtre `Material` dans le shell `MacosApp`. Root cause : usage d'un widget Material isolé dans une UI macOS. Correction : wrapper local `Material(type: MaterialType.transparency)` autour du `DropdownButton`, sans changer le shell.

### Mutation role -> animation

Extrait :

```dart
refsByRole[role] = SurfaceVariantAnimationRef(
  role: role,
  animationId: nextAnimationId,
);

final orderedRefs = <SurfaceVariantAnimationRef>[];
for (final standardRole in standardSurfaceVariantRoleOrder) {
  final ref = refsByRole[standardRole];
  if (ref != null) {
    orderedRefs.add(ref);
  }
}
```

### Limites V0

- Pas de suppression de mapping.
- Pas de rendu atlas dans l'éditeur de mapping.
- Pas de validation avancée animation/atlas dans cette UI.

## Git status final

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart
?? packages/map_editor/test/surface_studio/surface_studio_preset_editor_controller_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart
?? reports/surface/surface_engine_lot_88_bis_surface_studio_role_mapping_editor.md
```

Commande :

```text
git diff --stat
```

Sortie :

```text
 .../surface_studio_paintable_surfaces_panel.dart   |  60 ++++++++++-
 .../surface_studio/surface_studio_panel.dart       |  50 +++++++++
 .../surface_studio/surface_studio_panel_test.dart  | 113 +++++++++++++++++++++
 3 files changed, 218 insertions(+), 5 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis ; ils sont listés dans le status et dans `Fichiers créés`.

## Changements préexistants

Aucun : le Gate 0 était clean.

## Changements du Lot 88-bis

Tous les fichiers listés dans `Fichiers créés` et `Fichiers modifiés`.

## Périmètre explicitement non touché

- ProjectManifest non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- Codecs Surface non modifiés.
- `map_core` non modifié.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- Aucun renderer runtime Surface créé.
- Aucun resolver runtime Surface créé.
- Aucune animation clock runtime créée.
- Aucune migration legacy codée.
- Aucun provider/repository/service Surface créé.
- Aucune modification JSON.
- `Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

Commande :

```text
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie : vide.

Commande :

```text
git diff --check
```

Sortie : vide.

## Vérification mojibake

Commande :

```text
rg -n "Ã|Â|�" <fichiers Dart modifiés/créés + rapport>
```

Sortie : aucune correspondance.

## Auto-review

- Est-ce que l’utilisateur peut modifier rôle → animation ? Oui.
- Est-ce que les rôles standard sont listés ? Oui.
- Est-ce que les animations disponibles sont listées ? Oui.
- Est-ce qu’un rôle non couvert peut être associé à une animation ? Oui.
- Est-ce que les autres rôles restent inchangés ? Oui.
- Est-ce que le catalogue de travail devient dirty ? Oui.
- Est-ce que le save flow existant reste disponible ? Oui.
- Est-ce que le preset conserve id/name/categoryId/sortOrder ? Oui.
- Est-ce qu’une preview 3×3 ou équivalent existe ? Oui.
- Est-ce que Surface Painter fonctionne toujours ? Oui.
- Est-ce que Surface Studio fonctionne toujours ? Oui.
- Est-ce que map_core est modifié ? Non.
- Est-ce que map_runtime est modifié ? Non.
- Est-ce qu’un renderer runtime est créé ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les analyses ciblées passent ? Oui.
- Est-ce qu’un 88-ter est nécessaire ? Non pour ce périmètre. Un futur lot pourra rendre le mapping plus visuel avec des mini-frames, mais le blocage de correction rôle -> animation est levé.

## Critique du prompt

- Le prompt vise juste : corriger le mapping avant d'ajouter encore plus de rendu évite d'animer des erreurs.
- Demander une preview 3x3 est utile, mais elle reste conceptuelle car les rôles avancés dépassent naturellement une grille 3x3.
- L'option `Aucune animation` aurait augmenté le risque de preset invalide ; la limiter hors V0 est un meilleur compromis.
- La UI macOS + `DropdownButton` Material crée une friction technique mineure ; le wrapper local évite une refonte de contrôles.
