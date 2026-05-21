# Shadow-32 - Instance Shadow Footprint Override UI V0

## 1. Resume du lot

Shadow-32 ajoute l'edition du footprint d'ombre au niveau instance placee dans `PlacedElementShadowOverrideSection`.

Le lot expose en mode `Personnaliser` :

- `MapPlacedElementShadowOverride.footprint.anchorXRatio`
- `MapPlacedElementShadowOverride.footprint.anchorYRatio`
- `MapPlacedElementShadowOverride.footprint.footprintWidthRatio`
- `MapPlacedElementShadowOverride.footprint.footprintHeightRatio`

Le reset footprint ecrit `footprint: null` sans reinitialiser tout l'override. Le reset override existant continue a emettre `null`.

## 2. Design retenu

Design inline dans `PlacedElementShadowOverrideSection`, sans helper partage avec `ElementShadowSection` et sans modification du read model.

Le widget ajoute :

- quatre `TextEditingController` footprint ;
- une map d'erreurs footprint dediee ;
- un enum prive `_PlacedShadowFootprintField` ;
- `_parseFootprintNumber(...)` ;
- `_updatedFootprint(...)` ;
- un parametre `footprint` sur `_customOverride(...)` avec sentinel preserve.

Le helper `applyPlacedElementShadowTuningPreset(...)` preserve maintenant le `footprint` seulement si l'override courant est en mode `custom`.

## 3. Fichiers crees

- `reports/shadows/shadow_lot_32_instance_shadow_footprint_override_ui.md`

## 4. Fichiers modifies

- `packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart`
- `packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart`
- `packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart`

## 5. Fichiers non modifies explicitement

- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/**`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart`
- `packages/map_editor/lib/src/ui/canvas/**`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`

Aucun fichier non suivi preexistant hors lot n'etait present au status initial.

## 6. UI "Empreinte de cette instance"

Le bloc `Empreinte de cette instance` est rendu uniquement quand le read model est en mode `custom`, donc dans l'UI `Personnaliser`.

Il est place dans l'ordre suivant :

```text
Profil Shadow
Reglages rapides
Empreinte de cette instance
Offset / Scale / Opacite
```

Le texte d'aide explique que le footprint remplace celui de l'element uniquement pour cette instance, et que les champs vides heritent de l'element.

## 7. Champs footprint override ajoutes

Champs ajoutes :

- `Ancre X`
- `Ancre Y`
- `Largeur d'empreinte`
- `Hauteur d'empreinte`

Keys de test :

- `placed-shadow-footprint-anchorX-field`
- `placed-shadow-footprint-anchorY-field`
- `placed-shadow-footprint-width-field`
- `placed-shadow-footprint-height-field`
- `placed-shadow-footprint-reset-button`

## 8. Validation UX

Regles implementees :

- `anchorXRatio` : vide ou nombre fini entre `0` et `1` inclus ;
- `anchorYRatio` : vide ou nombre fini entre `0` et `1` inclus ;
- `footprintWidthRatio` : vide ou nombre fini strictement `> 0` ;
- `footprintHeightRatio` : vide ou nombre fini strictement `> 0`.

Messages :

- `Nombre invalide`
- `Doit etre entre 0 et 1`
- `Doit etre > 0`

Une valeur invalide affiche l'erreur et n'appelle pas `onChanged`.

## 9. Gestion footprint null / partiel / reset

Un champ vide devient `null`.

`_updatedFootprint(...)` reconstruit un `StaticShadowFootprintConfig` partiel si au moins un champ est non-null. Si les quatre champs sont null, elle retourne `null`.

Le reset footprint seul appelle :

```dart
_customOverride(footprint: null)
```

Cela conserve `mode: custom` et les autres champs custom.

## 10. Conservation des champs custom existants

`_customOverride()` sans argument preserve maintenant :

- `shadowProfileId`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`
- `footprint`

Les modifications de profil, offset, scale, opacity et footprint utilisent ce chemin.

## 11. Interaction avec les presets rapides Shadow-25

`applyPlacedElementShadowTuningPreset(...)` conserve le footprint uniquement si `currentOverride.mode == ShadowOverrideMode.custom`.

Comportement :

- preset sur custom avec footprint : footprint conserve ;
- preset sur null : footprint null ;
- preset sur disabled : footprint null ;
- preset sur inherit explicite : footprint null ;
- aucun preset ne cree de footprint.

## 12. Pourquoi ce lot ne touche pas runtime/canvas

Le runtime et la preview canvas consomment deja `MapPlacedElementShadowOverride.footprint` depuis les lots precedents. Shadow-32 ajoute seulement l'authoring UI de ce champ deja existant.

## 13. Pourquoi ce lot ne cree pas de direction globale de lumiere

Les champs edites sont des ratios locaux d'ancre et d'emprise de l'ombre pour une instance. Ils ne representent pas une source lumineuse globale, une direction de soleil, un `timeOfDay` ou un etat global.

## 14. Tests ajoutes/modifies

Tests helper ajoutes :

- footprint null sur preset depuis `null` ;
- footprint null sur preset depuis `disabled` ;
- preservation du footprint depuis un override `custom`.

Tests widget ajoutes :

- bloc absent en inherit et disabled ;
- bloc present en custom ;
- champs vides en custom sans footprint ;
- footprint partiel synchronise dans les champs ;
- modification des quatre ratios ;
- erreurs anchor / width invalides sans `onChanged` ;
- reset footprint garde l'override custom ;
- reset override garde son comportement `null` ;
- vider le dernier champ footprint garde `mode: custom` et met `footprint: null` ;
- changement profil / scale / preset preserve footprint.

## 15. Commandes lancees

```bash
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/placed_instances test/application/shadow test/features/tileset_library
cd packages/map_core && dart test test/shadow/static_shadow_footprint_config_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all
cd /Users/karim/Project/pokemonProject && find .. -name AGENTS.md -print
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
cd /Users/karim/Project/pokemonProject && git diff --check
cd /Users/karim/Project/pokemonProject && git diff --stat
cd /Users/karim/Project/pokemonProject && git diff --name-status
```

## 16. Resultats complets des tests cibles

### RED - `flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
00:00 +0: createPlacedElementShadowTuningPresets returns stable unique preset ids
00:00 +1: createPlacedElementShadowTuningPresets keeps every preset within valid numeric ranges
00:00 +2: applyPlacedElementShadowTuningPreset applies compact footprint values to a null override
00:00 +3: applyPlacedElementShadowTuningPreset does not inherit a profile id from disabled overrides
00:00 +4: applyPlacedElementShadowTuningPreset preserves a profile id from custom overrides
00:00 +5: applyPlacedElementShadowTuningPreset preserves footprint from custom overrides
00:00 +5 -1: applyPlacedElementShadowTuningPreset preserves footprint from custom overrides [E]
  Expected: <Instance of 'StaticShadowFootprintConfig'>
    Actual: <null>
00:00 +5 -1: applyPlacedElementShadowTuningPreset applies exact cast direction values
00:00 +6 -1: Some tests failed.
```

### GREEN - `flutter test test/application/shadow/placed_element_shadow_tuning_presets_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
00:00 +0: createPlacedElementShadowTuningPresets returns stable unique preset ids
00:00 +1: createPlacedElementShadowTuningPresets keeps every preset within valid numeric ranges
00:00 +2: applyPlacedElementShadowTuningPreset applies compact footprint values to a null override
00:00 +3: applyPlacedElementShadowTuningPreset does not inherit a profile id from disabled overrides
00:00 +4: applyPlacedElementShadowTuningPreset preserves a profile id from custom overrides
00:00 +5: applyPlacedElementShadowTuningPreset preserves footprint from custom overrides
00:00 +6: applyPlacedElementShadowTuningPreset applies exact cast direction values
00:00 +7: All tests passed!
```

### RED - `flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
00:00 +0: PlacedElementShadowOverrideSection shows the section title and inherit mode for null override
00:00 +1: PlacedElementShadowOverrideSection disabled mode emits a disabled override
00:00 +2: PlacedElementShadowOverrideSection custom mode emits custom override and reset emits null
00:00 +3: PlacedElementShadowOverrideSection number fields update custom offset scale and opacity
00:01 +4: PlacedElementShadowOverrideSection invalid scale and opacity values do not emit changes
00:01 +5: PlacedElementShadowOverrideSection profile dropdown filters actorContact and none profiles
00:01 +6: PlacedElementShadowOverrideSection empty catalog shows seed action
00:01 +7: PlacedElementShadowOverrideSection quick tuning presets appear only in custom mode
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Empreinte de cette instance": []>
00:01 +7 -1: PlacedElementShadowOverrideSection quick tuning presets appear only in custom mode [E]
00:02 +7 -2: PlacedElementShadowOverrideSection custom footprint null and partial values sync text fields [E]
00:02 +7 -3: PlacedElementShadowOverrideSection footprint fields update ratios and preserve custom fields [E]
00:02 +7 -4: PlacedElementShadowOverrideSection invalid footprint values show errors and do not emit changes [E]
00:02 +7 -5: PlacedElementShadowOverrideSection reset and clearing last footprint field keep custom override [E]
00:02 +7 -6: PlacedElementShadowOverrideSection profile number changes and presets preserve footprint [E]
00:03 +10 -6: Some tests failed.
```

### GREEN - `flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
00:00 +0: PlacedElementShadowOverrideSection shows the section title and inherit mode for null override
00:00 +1: PlacedElementShadowOverrideSection disabled mode emits a disabled override
00:00 +2: PlacedElementShadowOverrideSection custom mode emits custom override and reset emits null
00:00 +3: PlacedElementShadowOverrideSection number fields update custom offset scale and opacity
00:01 +4: PlacedElementShadowOverrideSection invalid scale and opacity values do not emit changes
00:01 +5: PlacedElementShadowOverrideSection profile dropdown filters actorContact and none profiles
00:01 +6: PlacedElementShadowOverrideSection empty catalog shows seed action
00:01 +7: PlacedElementShadowOverrideSection quick tuning presets appear only in custom mode
00:01 +8: PlacedElementShadowOverrideSection custom footprint null and partial values sync text fields
00:01 +9: PlacedElementShadowOverrideSection footprint fields update ratios and preserve custom fields
00:02 +10: PlacedElementShadowOverrideSection invalid footprint values show errors and do not emit changes
00:02 +11: PlacedElementShadowOverrideSection reset and clearing last footprint field keep custom override
00:02 +12: PlacedElementShadowOverrideSection profile number changes and presets preserve footprint
00:02 +13: PlacedElementShadowOverrideSection compact preset emits expected custom override values
00:02 +14: PlacedElementShadowOverrideSection cast presets apply the expected offset directions
00:02 +15: PlacedElementShadowOverrideSection preset preserves a selected custom profile id
00:02 +16: All tests passed!
```

### `dart test test/shadow/static_shadow_footprint_config_test.dart`

```text
00:00 +0: loading test/shadow/static_shadow_footprint_config_test.dart
00:00 +0: StaticShadowFootprintConfig constructor all null is empty
00:00 +1: StaticShadowFootprintConfig constructor all null is empty
00:00 +1: StaticShadowFootprintConfig accepts anchor ratios at bounds
00:00 +2: StaticShadowFootprintConfig accepts anchor ratios at bounds
00:00 +2: StaticShadowFootprintConfig rejects anchor ratios outside 0 to 1 or non-finite
00:00 +3: StaticShadowFootprintConfig rejects anchor ratios outside 0 to 1 or non-finite
00:00 +3: StaticShadowFootprintConfig accepts positive footprint ratios
00:00 +4: StaticShadowFootprintConfig accepts positive footprint ratios
00:00 +4: StaticShadowFootprintConfig rejects footprint ratios that are not positive finite values
00:00 +5: StaticShadowFootprintConfig rejects footprint ratios that are not positive finite values
00:00 +5: StaticShadowFootprintConfig equality and hashCode include all fields
00:00 +6: StaticShadowFootprintConfig equality and hashCode include all fields
00:00 +6: All tests passed!
```

## 17. Ligne finale exacte des tests globaux cibles

### `flutter test test/application/shadow`

Resultat : exit code `0`.

Ligne finale exacte :

```text
00:00 +52: All tests passed!
```

### `flutter test test/features/tileset_library`

Resultat : exit code `0`.

Ligne finale exacte :

```text
00:05 +40: All tests passed!
```

### `flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/placed_instances test/application/shadow test/features/tileset_library`

Resultat : exit code `0`.

Sortie :

```text
Analyzing 4 items...
No issues found! (ran in 8.9s)
```

### `dart test test/shadow`

Resultat : exit code `0`.

Ligne finale exacte :

```text
00:00 +204: All tests passed!
```

### `dart analyze lib test/shadow`

Resultat : exit code `0`.

Sortie :

```text
Analyzing lib, shadow...
No issues found!
```

## 18. Resultats des scans anti-derive

### `find .. -name AGENTS.md -print`

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `../pokemonProject/AGENTS.md` s'applique au repo courant.

### Runtime/gameplay/battle

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Resultat : exit code `1`, aucune ligne imprimee.

### Core models/codecs

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Resultat : exit code `1`, aucune ligne imprimee.

### Canvas/painter

Commande :

```bash
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/canvas"
```

Resultat : exit code `1`, aucune ligne imprimee.

### Renderer / lumiere globale

Commande :

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "Canvas|drawOval|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Resultat : exit code `1`, aucune ligne imprimee.

### Import runtime

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Resultat : exit code `1`, aucune ligne imprimee.

### `git diff --check`

Resultat : exit code `0`, aucune ligne imprimee.

## 19. git status initial

Avant implementation :

```text
```

Interpretation : aucune modification suivie ou non suivie n'etait presente au debut du lot.

## 20. git status final

Apres implementation et creation du rapport :

```text
 M packages/map_editor/lib/src/application/shadow/placed_element_shadow_tuning_presets.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
 M packages/map_editor/test/application/shadow/placed_element_shadow_tuning_presets_test.dart
 M packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
?? reports/shadows/shadow_lot_32_instance_shadow_footprint_override_ui.md
```

## 21. git diff --stat

Avant creation du rapport :

```text
 .../placed_element_shadow_tuning_presets.dart      |   4 +
 .../placed_element_shadow_override_section.dart    | 272 ++++++++++++++++++++-
 .../placed_element_shadow_tuning_presets_test.dart |  23 ++
 ...laced_element_shadow_override_section_test.dart | 232 ++++++++++++++++++
 4 files changed, 528 insertions(+), 3 deletions(-)
```

## 22. Non-objectifs respectes

- Aucun runtime modifie.
- Aucun canvas/painter modifie.
- Aucun modele/core codec modifie.
- Aucun `EditorNotifier` modifie.
- Aucun Shadow Studio cree.
- Aucune lumiere globale creee.
- Aucun renderer cree.
- Aucun build_runner lance.
- Aucun commit effectue.

## 23. Risques / reserves

- Le widget d'override d'instance gagne un bloc supplementaire en mode custom. Il reste inline et compact, mais le panneau devient progressivement dense avec les lots Shadow.
- La logique footprint est proche de celle de `ElementShadowSection`, mais non factorisee volontairement pour eviter un helper premature entre deux widgets qui n'emettent pas le meme type.
- Le test RED widget a aussi affiche un message `Waiting for another flutter command to release the startup lock...` parce que deux commandes Flutter avaient ete lancees en parallele. Les reruns verts ont ensuite ete executes sequentiellement.

## 24. Auto-review finale

- Ai-je ajoute l'UI footprint au niveau instance ? oui.
- Ai-je evite de toucher au runtime ? oui.
- Ai-je evite de toucher a la preview canvas ? oui.
- Ai-je evite de modifier les modeles/codecs core ? oui.
- Ai-je conserve `shadowProfileId` ? oui.
- Ai-je conserve `offset/scale/opacity` ? oui.
- Ai-je valide les anchors dans `0..1` ? oui.
- Ai-je valide footprint width/height `> 0` ? oui.
- Ai-je represente reset footprint par `footprint null` ? oui.
- Ai-je conserve mode custom lors d'un reset footprint seul ? oui.
- Ai-je preserve footprint lors d'un preset rapide ? oui.
- Ai-je evite de creer une lumiere globale ? oui.

## 25. Regard critique sur le prompt

Le prompt est coherent avec la separation Shadow-31 / Shadow-32. Le point le plus risqué etait l'interaction entre presets rapides et footprint : sans test explicite, appliquer un preset aurait continue a effacer l'empreinte locale. Le design valide permet de corriger ce risque sans toucher au runtime ni au read model.

## 26. Contenu complet des fichiers crees/modifies

Les fichiers modifies principaux sont longs. Les sections modifiees completes sont identifiees ci-dessous et le diff du lot est inclus en section 27.

Sections modifiees :

- `placed_element_shadow_tuning_presets.dart` : preservation de `footprint` dans `applyPlacedElementShadowTuningPreset(...)`.
- `placed_element_shadow_override_section.dart` : controllers footprint, UI `Empreinte de cette instance`, validation, reset footprint, extension de `_customOverride(...)`, synchronisation controllers.
- `placed_element_shadow_tuning_presets_test.dart` : assertions footprint null et test preservation footprint custom.
- `placed_element_shadow_override_section_test.dart` : tests widget footprint instance et helper `_fieldText(...)`.

Le fichier cree est ce rapport.

## 27. Diffs complets ou equivalence /dev/null pour fichiers crees

### Sections de code modifiees

`placed_element_shadow_tuning_presets.dart` :

```dart
MapPlacedElementShadowOverride applyPlacedElementShadowTuningPreset({
  required PlacedElementShadowTuningPreset preset,
  MapPlacedElementShadowOverride? currentOverride,
}) {
  final shadowProfileId = currentOverride?.mode == ShadowOverrideMode.custom
      ? currentOverride?.shadowProfileId
      : null;
  final footprint = currentOverride?.mode == ShadowOverrideMode.custom
      ? currentOverride?.footprint
      : null;
  return MapPlacedElementShadowOverride(
    mode: ShadowOverrideMode.custom,
    shadowProfileId: shadowProfileId,
    offsetX: preset.offsetX,
    offsetY: preset.offsetY,
    scaleX: preset.scaleX,
    scaleY: preset.scaleY,
    opacity: preset.opacity,
    footprint: footprint,
  );
}
```

`placed_element_shadow_override_section.dart`, widgets footprint :

```dart
  Widget _footprintSection(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final hasFootprint = widget.shadowOverride?.footprint != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Empreinte de cette instance',
          style: TextStyle(
            color: label,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Remplace l’empreinte de l’élément uniquement pour cette instance. Laissez vide pour hériter de l’élément.',
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _footprintField(
                context,
                _PlacedShadowFootprintField.anchorX,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footprintField(
                context,
                _PlacedShadowFootprintField.anchorY,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _footprintField(
                context,
                _PlacedShadowFootprintField.width,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _footprintField(
                context,
                _PlacedShadowFootprintField.height,
              ),
            ),
          ],
        ),
        if (hasFootprint) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: PushButton(
              key: const ValueKey('placed-shadow-footprint-reset-button'),
              controlSize: ControlSize.small,
              secondary: true,
              onPressed: _resetFootprint,
              child: const Text('Réinitialiser l’empreinte de l’instance'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _footprintField(
    BuildContext context,
    _PlacedShadowFootprintField field,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final error = _footprintErrors[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        MacosTextField(
          key: ValueKey('placed-shadow-footprint-${field.keyName}-field'),
          controller: _footprintControllerFor(field),
          placeholder: 'auto',
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          onChanged: (value) => _setFootprintNumber(field, value),
        ),
        if (error != null) ...[
          const SizedBox(height: 3),
          Text(
            error,
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(context),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
```

`placed_element_shadow_override_section.dart`, mutations et validation :

```dart
  void _setFootprintNumber(
    _PlacedShadowFootprintField field,
    String rawValue,
  ) {
    final parsed = _parseFootprintNumber(field, rawValue);
    if (parsed?.isNaN == true) return;
    widget.onChanged(
      _customOverride(
        footprint: _updatedFootprint(
          _currentCustomOverride?.footprint,
          field: field,
          value: parsed,
        ),
      ),
    );
  }

  void _resetFootprint() {
    setState(_footprintErrors.clear);
    widget.onChanged(_customOverride(footprint: null));
  }

  double? _parseFootprintNumber(
    _PlacedShadowFootprintField field,
    String rawValue,
  ) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      setState(() => _footprintErrors.remove(field));
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) {
      setState(() => _footprintErrors[field] = 'Nombre invalide');
      return _invalidPlacedShadowNumber;
    }
    if (field.isAnchor && (parsed < 0 || parsed > 1)) {
      setState(() => _footprintErrors[field] = 'Doit être entre 0 et 1');
      return _invalidPlacedShadowNumber;
    }
    if (!field.isAnchor && parsed <= 0) {
      setState(() => _footprintErrors[field] = 'Doit être > 0');
      return _invalidPlacedShadowNumber;
    }
    setState(() => _footprintErrors.remove(field));
    return parsed;
  }
```

`placed_element_shadow_override_section.dart`, `_customOverride(...)` footprint :

```dart
  MapPlacedElementShadowOverride _customOverride({
    Object? shadowProfileId = _preservePlacedShadowValue,
    Object? offsetX = _preservePlacedShadowValue,
    Object? offsetY = _preservePlacedShadowValue,
    Object? scaleX = _preservePlacedShadowValue,
    Object? scaleY = _preservePlacedShadowValue,
    Object? opacity = _preservePlacedShadowValue,
    Object? footprint = _preservePlacedShadowValue,
  }) {
    final current = _currentCustomOverride;
    return MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.custom,
      shadowProfileId: identical(shadowProfileId, _preservePlacedShadowValue)
          ? current?.shadowProfileId
          : shadowProfileId as String?,
      offsetX: identical(offsetX, _preservePlacedShadowValue)
          ? current?.offsetX
          : offsetX as double?,
      offsetY: identical(offsetY, _preservePlacedShadowValue)
          ? current?.offsetY
          : offsetY as double?,
      scaleX: identical(scaleX, _preservePlacedShadowValue)
          ? current?.scaleX
          : scaleX as double?,
      scaleY: identical(scaleY, _preservePlacedShadowValue)
          ? current?.scaleY
          : scaleY as double?,
      opacity: identical(opacity, _preservePlacedShadowValue)
          ? current?.opacity
          : opacity as double?,
      footprint: identical(footprint, _preservePlacedShadowValue)
          ? current?.footprint
          : footprint as StaticShadowFootprintConfig?,
    );
  }
```

`placed_element_shadow_override_section.dart`, footprint enum et merge :

```dart
enum _PlacedShadowFootprintField {
  anchorX('anchorX', 'Ancre X'),
  anchorY('anchorY', 'Ancre Y'),
  width('width', 'Largeur d’empreinte'),
  height('height', 'Hauteur d’empreinte');

  const _PlacedShadowFootprintField(this.keyName, this.label);

  final String keyName;
  final String label;

  bool get isAnchor =>
      this == _PlacedShadowFootprintField.anchorX ||
      this == _PlacedShadowFootprintField.anchorY;
}

StaticShadowFootprintConfig? _updatedFootprint(
  StaticShadowFootprintConfig? current, {
  required _PlacedShadowFootprintField field,
  required double? value,
}) {
  final anchorX = field == _PlacedShadowFootprintField.anchorX
      ? value
      : current?.anchorXRatio;
  final anchorY = field == _PlacedShadowFootprintField.anchorY
      ? value
      : current?.anchorYRatio;
  final width = field == _PlacedShadowFootprintField.width
      ? value
      : current?.footprintWidthRatio;
  final height = field == _PlacedShadowFootprintField.height
      ? value
      : current?.footprintHeightRatio;

  if (anchorX == null && anchorY == null && width == null && height == null) {
    return null;
  }

  return StaticShadowFootprintConfig(
    anchorXRatio: anchorX,
    anchorYRatio: anchorY,
    footprintWidthRatio: width,
    footprintHeightRatio: height,
  );
}
```

Tests ajoutes dans `placed_element_shadow_tuning_presets_test.dart` :

```dart
      expect(override.footprint, isNull);

    test('preserves footprint from custom overrides', () {
      final preset = _preset('compact-footprint');
      final footprint = StaticShadowFootprintConfig(
        anchorXRatio: 0.25,
        anchorYRatio: 0.75,
        footprintWidthRatio: 0.5,
        footprintHeightRatio: 0.2,
      );

      final override = applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
          footprint: footprint,
        ),
      );

      expect(override.mode, ShadowOverrideMode.custom);
      expect(override.footprint, footprint);
    });
```

Tests ajoutes dans `placed_element_shadow_override_section_test.dart` :

```dart
    testWidgets('custom footprint null and partial values sync text fields',
        (tester) async { ... });
    testWidgets('footprint fields update ratios and preserve custom fields',
        (tester) async { ... });
    testWidgets('invalid footprint values show errors and do not emit changes',
        (tester) async { ... });
    testWidgets('reset and clearing last footprint field keep custom override',
        (tester) async { ... });
    testWidgets('profile number changes and presets preserve footprint',
        (tester) async { ... });
```

### Fichier cree

`reports/shadows/shadow_lot_32_instance_shadow_footprint_override_ui.md` est le fichier cree ; son contenu est ce document.
