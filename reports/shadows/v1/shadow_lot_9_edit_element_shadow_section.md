# Shadow Lot 9 — Edit Element Shadow Section V0

## 1. Résumé

Shadow-9 ajoute une section “Ombre de l’élément” dans Edit Element.
La section permet de configurer `ProjectElementEntry.shadow` via l’UI existante.
Elle consomme `ElementShadowReadModel` et n’ajoute aucun rendu, aucun canvas, aucun runtime, aucun gameplay et aucun override instance.

La distinction est conservée :

- `shadow == null` : aucune config Shadow.
- `shadow.castsShadow == false` : config présente, ombre désactivée.
- `shadow.castsShadow == true` : ombre active si le profil est valide.

## 2. Fichiers créés

- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`
- `packages/map_editor/test/features/tileset_library/project_element_shadow_update_use_case_test.dart`
- `reports/shadows/shadow_lot_9_edit_element_shadow_section.md`

Note : les fichiers Shadow-8 suivants étaient déjà non suivis au début du lot et ont été conservés :

- `packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart`
- `packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart`
- `reports/shadows/shadow_lot_8_editor_read_model.md`

## 3. Fichiers modifiés

- `packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`

## 4. UI ajoutée

Emplacement exact :

- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- Dans la modale `Edit Element`
- Après le sélecteur `Type`
- Avant `_ElementCollisionProfileSummaryCard`

Contrôles visibles :

- Titre `Ombre de l’élément`
- Statut lisible : `Non configurée`, `Désactivée`, `Active`, `Profil manquant`, `Profil sans ombre`
- Switch `Projette une ombre`
- Dropdown des profils Shadow du manifest
- Champs numériques nullable : `Offset X`, `Offset Y`, `Scale X`, `Scale Y`, `Opacité`
- Bouton `Réinitialiser la config`
- Diagnostics lisibles de profil manquant

Comportement :

- Activation depuis `shadow == null` crée une config active avec le premier profil disponible.
- Désactivation via switch conserve le profil et les overrides, mais passe `castsShadow` à `false`.
- Réinitialisation met `shadow` à `null`.
- Catalogue vide : l’activation est désactivée et le message `Aucun profil Shadow disponible.` est affiché.

## 5. Intégration au flux Edit Element

Le flux existant de sauvegarde est conservé :

- La modale garde un draft local `ProjectElementShadowConfig? shadowConfig`.
- `ElementShadowSection` appelle `onChanged`.
- Le bouton Save appelle `EditorNotifier.updateProjectElement(...)`.
- `EditorNotifier` délègue à `UpdateProjectElementUseCase.execute(...)`.
- `UpdateProjectElementUseCase` applique `shadow` ou `clearShadow`, puis persiste le `ProjectManifest` via le repository existant.

Aucun repository, provider, service ou système de persistance parallèle n’a été ajouté.

Une validation protège l’ambiguïté demandée :

```dart
if (shadow != null && clearShadow) {
  throw const EditorValidationException(
    'Cannot set and clear element shadow in the same update',
  );
}
```

## 6. Utilisation du read model Shadow

Le widget dédié utilise :

- `buildElementShadowReadModel(...)`
- `ElementShadowReadStatus`
- `ShadowProfileOptionReadModel`
- `ElementShadowDiagnosticReadModel`

Le widget ne réimplémente pas le resolver Shadow. Il crée seulement un élément de lecture temporaire avec :

```dart
final element = widget.element.copyWith(shadow: widget.shadow);
final readModel = buildElementShadowReadModel(
  manifest: widget.manifest,
  element: element,
);
```

La logique UI locale se limite à :

- mapper les statuts vers des labels/couleurs ;
- émettre une nouvelle `ProjectElementShadowConfig` valide ;
- afficher les diagnostics du read model.

## 7. États UI supportés

- `notConfigured` -> `Non configurée`
- `disabled` -> `Désactivée`
- `active` -> `Active`
- `missingProfile` -> `Profil manquant`
- `profileNone` -> `Profil sans ombre`

`profileNone` reste informatif : aucun diagnostic d’erreur n’est affiché quand le profil existe et que son `mode` vaut `ShadowCasterMode.none`.

## 8. Validation des champs

Règles implémentées :

- Champ vide -> `null`
- `offsetX` / `offsetY` acceptent les valeurs négatives
- `scaleX` / `scaleY` doivent être `> 0`
- `opacity` doit être entre `0` et `1`
- valeurs non finies ou non numériques refusées
- les erreurs locales n’émettent pas de modèle invalide

Le formatter d’entrée autorise uniquement chiffres, point et signe moins pour éviter les chaînes comme `NaN`, `Infinity`, `abc` ou `1,2`.

## 9. Diagnostics affichés

Le diagnostic principal affiché est :

- `missingShadowProfile` -> `Profil Shadow introuvable : <id>`

Si aucun diagnostic n’est présent, aucun bloc d’erreur vide n’est rendu.

## 10. Tests ajoutés

`element_shadow_section_test.dart` couvre :

- présence de la section ;
- insertion avant `_ElementCollisionProfileSummaryCard` ;
- état `Non configurée` ;
- catalogue vide et activation désactivée ;
- activation depuis `shadow == null` ;
- désactivation qui conserve profil et overrides ;
- reset qui remet `shadow` à `null` ;
- changement de profil ;
- édition et vidage d’un champ numérique nullable ;
- rejet de `scaleX` invalide ;
- rejet de `opacity` invalide ;
- diagnostic de profil manquant ;
- profil `none` informatif ;
- absence de champs interdits V0 (`blur`, `zOrder`, `renderPass`, `softness`, `color`).

`project_element_shadow_update_use_case_test.dart` couvre :

- persistance de `shadow` ;
- non-mutation de `collisionProfile` ;
- `clearShadow` -> `shadow == null` ;
- rejet de `shadow != null && clearShadow == true`.

## 11. Commandes lancées

```bash
git status --short --untracked-files=all
dart format packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart packages/map_editor/test/features/tileset_library/project_element_shadow_update_use_case_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart test/features/tileset_library/project_element_shadow_update_use_case_test.dart
cd packages/map_editor && flutter test test/application/shadow test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test
rg -n "runtimeBlur|blurRadius|zOrder|zIndex|modeOverride|colorOverride|renderPassOverride|softnessOverride|shadowTilesetId|shadowSource|sourceMaskId|WorldLightState|ShadowLightProfile" packages/map_editor/lib packages/map_editor/test
rg -n "drawOval|drawPath|drawImageRect|Canvas|CustomPainter|Flame|ShadowRuntimeRenderInstruction|MapLayersComponent|PlayerComponent|OverworldActorComponent" packages/map_editor/lib packages/map_editor/test packages/map_runtime/lib
rg -n "collisionMask|occlusionMask|visualMask|cells|applyCollision" packages/map_editor/lib packages/map_editor/test
find packages/map_editor/lib -name "*.g.dart" -o -name "*.freezed.dart"
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 12. Résultats des tests ciblés

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart test/features/tileset_library/project_element_shadow_update_use_case_test.dart
```

Résultat final :

```text
00:01 +15: All tests passed!
```

## 13. Résultat de flutter analyze ciblé

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library
```

Résultat final :

```text
No issues found! (ran in 2.7s)
```

## 14. Résultat des tests Shadow map_core

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final :

```text
00:00 +152: All tests passed!
```

## 15. Résultat du test complet map_editor

Commande :

```bash
cd packages/map_editor && flutter test
```

Résultat final :

```text
01:32 +1410 -45: Some tests failed.
```

Échecs observés hors lot :

- Plusieurs tests existants utilisent encore des `const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog())`, alors que `ProjectSurfaceCatalog()` n’est pas const.
- `project_element_collision_file_repository_roundtrip_test.dart` échoue sur une attente de cellules collision héritée.
- `pokemon_sdk_move_catalog_converter.dart` référence des types/champs de mouvements absents ou renommés (`PokemonMoveAimedTarget`, `PokemonMoveFlags`, `PokemonMoveBattleStageMod`, `PokemonMoveStatus`, `psdkStudioMoveId`, `dbSymbol`).
- `update_pokedex_species_learnset_use_case_test.dart` échoue sur un move id `protect` absent du catalogue local.

Preuve que Shadow-9 est vert malgré cela :

- tests ciblés Shadow-9 : `+15`
- tests Shadow map_editor : `+38`
- tests Shadow map_core : `+152`
- analyse ciblée : aucune issue

## 16. Build runner / génération

Build runner lancé : non.

Generated files : aucun nouveau fichier généré par Shadow-9.

Raison : Shadow-9 modifie uniquement une UI, le flux de sauvegarde applicatif et des tests. Aucun modèle Freezed/JsonSerializable n’a été modifié.

La commande :

```bash
find packages/map_editor/lib -name "*.g.dart" -o -name "*.freezed.dart"
```

liste des fichiers générés existants du package, mais aucun n’a été créé ou modifié par ce lot.

## 17. Vérifications anti-dérive

Confirmations :

- aucun `map_runtime` modifié ;
- aucun `map_gameplay` modifié ;
- aucun `map_battle` modifié ;
- aucun `MapCanvas` modifié ;
- aucun `MapGridPainter` modifié ;
- aucun renderer ajouté ;
- aucun preview canvas ajouté ;
- aucun `MapPlacedElement` override modifié ;
- aucun resolver core modifié ;
- aucun `ProjectManifest` map_core modifié ;
- aucun map_core modifié ;
- aucun `collisionMask` modifié ;
- aucun `occlusionMask` modifié ;
- aucun `visualMask` modifié ;
- aucun `cells` modifié en production ;
- aucun `runtimeBlur` ;
- aucun `zOrder` / `zIndex` ;
- aucun override `mode/color/renderPass/softness`.

Recherche champs interdits :

- Des occurrences `blurRadius` existent déjà dans des widgets/canvas existants, hors Shadow-9.
- Une occurrence `zOrder` existe dans `element_shadow_section_test.dart` uniquement pour vérifier que le texte interdit n’est pas rendu.

Recherche rendu/canvas :

- Les occurrences `Canvas`, `CustomPainter`, `Flame`, `MapLayersComponent`, `PlayerComponent`, `OverworldActorComponent`, `drawOval`, `drawPath`, `drawImageRect` sont existantes dans le runtime, le canvas ou les tests historiques.
- Aucun fichier Shadow-9 ne crée de rendu ou preview canvas.

Recherche collision/occlusion :

- Les occurrences existantes appartiennent aux services/widgets/tests collision et path/surface historiques.
- Shadow-9 ajoute seulement un test de non-mutation de `collisionProfile`.

`git diff --check` :

```text
aucune sortie
```

## 18. Git status initial

```text
?? packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
?? packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart
?? reports/shadows/shadow_lot_8_editor_read_model.md
```

## 19. Git status final

```text
 M packages/map_editor/lib/src/application/use_cases/project_element_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
?? packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
?? packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
?? packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart
?? packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
?? packages/map_editor/test/features/tileset_library/project_element_shadow_update_use_case_test.dart
?? reports/shadows/shadow_lot_8_editor_read_model.md
?? reports/shadows/shadow_lot_9_edit_element_shadow_section.md
```

## 20. Git diff stat final

`git diff --stat` pour les fichiers tracked :

```text
 .../application/use_cases/project_element_use_cases.dart  | 10 ++++++++++
 .../lib/src/features/editor/state/editor_notifier.dart    |  4 ++++
 .../lib/src/ui/panels/tileset_palette_panel.dart          | 15 +++++++++++++++
 3 files changed, 29 insertions(+)
```

Les fichiers créés sont non suivis, donc non inclus par `git diff --stat`.

## 21. Non-objectifs respectés

- Aucun rendu d’ombre.
- Aucun canvas preview.
- Aucun runtime Flame.
- Aucun Shadow Studio.
- Aucun override instance.
- Aucun `ShadowResolvedConfig` nouveau.
- Aucun resolver core nouveau.
- Aucun map_core modifié.
- Aucune collision modifiée.
- Aucune occlusion modifiée.
- Aucun gameplay modifié.

## 22. Risques / réserves

- Le test complet `map_editor` reste rouge sur des dettes hors Shadow-9. Les tests ciblés Shadow-9, Shadow map_editor, Shadow map_core et l’analyse ciblée passent.
- Les fichiers Shadow-8 étaient non suivis au départ et restent non suivis. Shadow-9 les consomme sans les supprimer.
- Le test d’insertion avant collision vérifie la structure source de la modale, ce qui est volontairement léger pour éviter un test d’intégration trop couplé au shell complet.

## 23. Prochain lot recommandé

Shadow-10 — Shadow Render Order Regression V0

Ne pas l’implémenter dans Shadow-9.

## 24. Code généré injecté

### 24.1 Widget dédié ElementShadowSection

```dart
class ElementShadowSection extends StatefulWidget {
  const ElementShadowSection({
    super.key,
    required this.manifest,
    required this.element,
    required this.shadow,
    required this.onChanged,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry element;
  final ProjectElementShadowConfig? shadow;
  final ValueChanged<ProjectElementShadowConfig?> onChanged;

  @override
  State<ElementShadowSection> createState() => _ElementShadowSectionState();
}
```

Lecture via `ElementShadowReadModel` :

```dart
final element = widget.element.copyWith(shadow: widget.shadow);
final readModel = buildElementShadowReadModel(
  manifest: widget.manifest,
  element: element,
);
```

Switch activer/désactiver avec conservation des réglages :

```dart
void _setCastsShadow(bool value) {
  final current = widget.shadow;
  if (!value) {
    if (current == null) return;
    widget.onChanged(
      ProjectElementShadowConfig(
        castsShadow: false,
        shadowProfileId: current.shadowProfileId,
        offsetX: current.offsetX,
        offsetY: current.offsetY,
        scaleX: current.scaleX,
        scaleY: current.scaleY,
        opacity: current.opacity,
      ),
    );
    return;
  }

  final profiles = widget.manifest.shadowCatalog.profiles;
  if (profiles.isEmpty) {
    setState(() {
      _activationMessage = 'Aucun profil Shadow disponible.';
    });
    return;
  }

  final currentProfileId = current?.shadowProfileId;
  final selectedProfileId = currentProfileId != null &&
          widget.manifest.shadowCatalog.profileById(currentProfileId) != null
      ? currentProfileId
      : profiles.first.id;
  setState(() {
    _activationMessage = null;
  });
  widget.onChanged(
    ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: selectedProfileId,
      offsetX: current?.offsetX,
      offsetY: current?.offsetY,
      scaleX: current?.scaleX,
      scaleY: current?.scaleY,
      opacity: current?.opacity,
    ),
  );
}
```

Validation nullable des nombres :

```dart
double? _parseNumber(_ShadowNumberField field, String rawValue) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    setState(() => _errors.remove(field));
    return null;
  }
  final parsed = double.tryParse(trimmed);
  if (parsed == null || !parsed.isFinite) {
    setState(() => _errors[field] = '${field.label} invalide.');
    return _invalidNumber;
  }
  if ((field == _ShadowNumberField.scaleX ||
          field == _ShadowNumberField.scaleY) &&
      parsed <= 0) {
    setState(() => _errors[field] = '${field.label} doit être > 0.');
    return _invalidNumber;
  }
  if (field == _ShadowNumberField.opacity && (parsed < 0 || parsed > 1)) {
    setState(() => _errors[field] = 'Opacité doit être entre 0 et 1.');
    return _invalidNumber;
  }
  setState(() => _errors.remove(field));
  return parsed;
}
```

Reset séparé de la désactivation :

```dart
PushButton(
  key: const ValueKey('element-shadow-reset-button'),
  controlSize: ControlSize.regular,
  secondary: true,
  onPressed: () {
    setState(() {
      _errors.clear();
      _activationMessage = null;
    });
    widget.onChanged(null);
  },
  child: const Text('Réinitialiser la config'),
)
```

### 24.2 Intégration Edit Element

Draft local :

```dart
ProjectElementShadowConfig? shadowConfig = element.shadow;
```

Insertion avant collision :

```dart
ElementShadowSection(
  manifest: project,
  element: element,
  shadow: shadowConfig,
  onChanged: (next) {
    setStateDialog(() {
      shadowConfig = next;
    });
  },
),
const SizedBox(height: 8),
_ElementCollisionProfileSummaryCard(
  source: frames.primarySource,
  tileWidth: tileWidth,
  tileHeight: tileHeight,
  profile: collisionProfile,
  padding: collisionPadding,
  onEdit: () async {
    // flux existant conservé
  },
)
```

Sauvegarde via le notifier existant :

```dart
await notifier.updateProjectElement(
  elementId: element.id,
  name: nameController.text,
  tilesetId: primaryTilesetId,
  categoryId: selectedCategoryId,
  groupId: selectedGroupId,
  clearGroupId: selectedGroupId == null,
  recommendedLayerId: selectedLayerId,
  clearRecommendedLayerId: selectedLayerId == null,
  shadow: shadowConfig,
  clearShadow: shadowConfig == null,
  frames: frames,
  tags: _parseTags(tagsController.text),
);
```

### 24.3 Use case / notifier

API ajoutée au use case :

```dart
ProjectElementShadowConfig? shadow,
bool clearShadow = false,
```

Validation anti-ambiguïté :

```dart
if (shadow != null && clearShadow) {
  throw const EditorValidationException(
    'Cannot set and clear element shadow in the same update',
  );
}
```

Application sur `ProjectElementEntry` :

```dart
final nextShadow = clearShadow ? null : (shadow ?? current.shadow);

return element.copyWith(
  name: nextName,
  categoryId: nextCategoryId,
  groupId: nextGroupId,
  presetKind: nextPresetKind,
  collisionProfile: nextCollisionProfile,
  recommendedLayerId: nextRecommendedLayerId,
  shadow: nextShadow,
  tags: nextTags,
);
```

Forwarding depuis `EditorNotifier.updateProjectElement(...)` :

```dart
shadow: shadow,
clearShadow: clearShadow,
```

### 24.4 Tests générés

Exemples de tests clés ajoutés :

```dart
testWidgets('reset clears the shadow config instead of disabling it',
    (tester) async {
  final harness = _ShadowSectionHarness(
    ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'tree_large',
    ),
  );

  await _pumpSection(
    tester,
    harness: harness,
    manifest: _project(_catalog([_profile('tree_large')])),
  );

  await tester.tap(
    find.byKey(const ValueKey('element-shadow-reset-button')),
  );
  await tester.pump();

  expect(harness.shadow, isNull);
  expect(harness.changes.last, isNull);
});
```

```dart
test('rejects setting and clearing shadow in the same update', () async {
  final repo = _FakeProjectRepository();
  final workspace = _FakeWorkspace();
  final useCase = UpdateProjectElementUseCase(repo);

  expect(
    () => useCase.execute(
      workspace,
      _project(_element()),
      elementId: 'tree_element',
      shadow: ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'tree_large',
      ),
      clearShadow: true,
    ),
    throwsA(isA<EditorValidationException>()),
  );
});
```

```dart
test('persists element shadow without changing collisionProfile', () async {
  final repo = _FakeProjectRepository();
  final workspace = _FakeWorkspace();
  final useCase = UpdateProjectElementUseCase(repo);
  final collisionProfile = _collisionProfile();
  final initial = _project(
    _element(collisionProfile: collisionProfile),
  );
  final shadow = ProjectElementShadowConfig(
    castsShadow: true,
    shadowProfileId: 'tree_large',
    offsetX: 4,
    scaleY: 0.5,
    opacity: 0.35,
  );

  final updated = await useCase.execute(
    workspace,
    initial,
    elementId: 'tree_element',
    shadow: shadow,
  );

  final element = updated.elements.single;
  expect(element.shadow, shadow);
  expect(element.collisionProfile, collisionProfile);
  expect(repo.lastSavedProject!.elements.single.shadow, shadow);
  expect(
    repo.lastSavedProject!.elements.single.collisionProfile,
    collisionProfile,
  );
});
```
