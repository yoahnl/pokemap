# Shadow-31 - Element Shadow Footprint UI V0

## 1. Resume du lot

Shadow-31 ajoute dans `ElementShadowSection` une UI d'edition du footprint par defaut de l'ombre d'un element source. Le bloc `Empreinte au sol` est visible seulement quand `shadow != null && shadow.castsShadow == true`.

Le lot permet d'editer :

- `ProjectElementShadowConfig.footprint.anchorXRatio`
- `ProjectElementShadowConfig.footprint.anchorYRatio`
- `ProjectElementShadowConfig.footprint.footprintWidthRatio`
- `ProjectElementShadowConfig.footprint.footprintHeightRatio`

Le reset ecrit `footprint: null`. Les valeurs invalides affichent une erreur et ne declenchent pas `onChanged`.

## 2. Design retenu

Design inline dans `ElementShadowSection`, sans helper application separe :

- quatre `MacosTextField` controles par des `TextEditingController` dedies ;
- placeholder `auto` pour representer une valeur `null` ;
- bloc place apres le picker `Profil` et avant les champs `Offset / Scale / Opacite` ;
- reset local `Reinitialiser l'empreinte` visible uniquement si `shadow.footprint != null` ;
- reconstruction de `ProjectElementShadowConfig` en preservant les champs existants.

## 3. Fichiers crees

- `reports/shadows/shadow_lot_31_element_shadow_footprint_ui.md`

## 4. Fichiers modifies

- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`

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

Aucun fichier non suivi preexistant hors lot n'est apparu dans le premier `git status` verifiable de cette reprise de session.

## 6. UI "Empreinte au sol"

Le bloc ajoute :

- titre `Empreinte au sol` ;
- aide courte : `Ajuste la base utilisee pour calculer l'ombre de cet element. Les instances peuvent encore la personnaliser.` ;
- quatre champs en grille 2x2 ;
- bouton `Reinitialiser l'empreinte` si un footprint existe.

Le bloc n'est pas rendu pour `shadow == null` ni pour `castsShadow == false`.

## 7. Champs footprint ajoutes

Mapping :

- `Ancre X` vers `anchorXRatio`
- `Ancre Y` vers `anchorYRatio`
- `Largeur d'empreinte` vers `footprintWidthRatio`
- `Hauteur d'empreinte` vers `footprintHeightRatio`

Keys de test :

- `element-shadow-footprint-anchorX-field`
- `element-shadow-footprint-anchorY-field`
- `element-shadow-footprint-width-field`
- `element-shadow-footprint-height-field`
- `element-shadow-footprint-reset-button`

## 8. Validation UX

Regles implementees :

- anchors : vide ou nombre fini dans `[0, 1]` ;
- largeur/hauteur : vide ou nombre fini strictement `> 0` ;
- non numerique ou non fini : `Nombre invalide` ;
- anchor hors borne : `Doit etre entre 0 et 1` ;
- largeur/hauteur `<= 0` : `Doit etre > 0`.

Une valeur invalide met a jour le message d'erreur et retourne le sentinel interne invalide ; `onChanged` n'est pas appele.

## 9. Gestion footprint null / partiel / reset

Une valeur vide dans un champ devient `null`.

`_updatedFootprint(...)` reconstruit un `StaticShadowFootprintConfig` partiel si au moins un champ reste non-null. Si les quatre champs deviennent `null`, la fonction retourne `null`.

Le bouton reset reconstruit `ProjectElementShadowConfig` sans passer `footprint`, ce qui ecrit `footprint == null`.

## 10. Conservation des champs existants

Les reconstructions de `ProjectElementShadowConfig` conservent :

- `castsShadow`
- `shadowProfileId`
- `offsetX`
- `offsetY`
- `scaleX`
- `scaleY`
- `opacity`
- `footprint`

Les chemins corriges/couverts sont :

- `_setCastsShadow`
- `_setProfile`
- `_setNumber`
- `_setFootprintNumber`
- `_resetFootprint`

## 11. Pourquoi ce lot ne touche pas runtime/editor canvas

Shadow-31 est un lot d'authoring UI. Le runtime et la preview canvas consomment deja `ProjectElementShadowConfig.footprint` depuis les lots precedents. Aucun rendu ni ordre canvas n'avait besoin de changer pour exposer les champs dans la section element.

## 12. Pourquoi ce lot ne cree pas de direction globale de lumiere

Les champs ajoutes decrivent seulement l'ancre et l'emprise de base de l'ombre d'un element. Ils ne modelisent pas une source lumineuse, une direction solaire, un `timeOfDay`, ni un etat global.

## 13. Tests ajoutes/modifies

Tests ajoutes dans `element_shadow_section_test.dart` :

- `footprint block is visible only for active shadows`
- `footprint null and partial values sync text fields`
- `footprint fields update ratios and preserve shadow fields`
- `invalid footprint values show errors and do not emit changes`
- `reset and clearing the last footprint field write null`
- `existing profile toggle and number changes preserve footprint`

Un helper de test `_fieldText(...)` lit le texte des champs par key.

## 14. Commandes lancees

```bash
cd packages/map_editor && flutter test test/features/tileset_library/element_shadow_section_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library
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

## 15. Resultats complets des tests cibles

### `flutter test test/features/tileset_library/element_shadow_section_test.dart`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
00:00 +0: ElementShadowSection is inserted before the collision summary in Edit Element
00:00 +1: ElementShadowSection shows not configured state for a null shadow config
00:00 +2: ElementShadowSection shows seed action when the catalog has no compatible profiles
00:00 +3: ElementShadowSection actorContact-only catalog is treated as no compatible profile
00:00 +4: ElementShadowSection none-only catalog is treated as no compatible profile
00:00 +5: ElementShadowSection after seed the default profiles appear in the dropdown
00:00 +6: ElementShadowSection activating from null creates an active config with first profile
00:00 +7: ElementShadowSection disabling preserves the selected profile and overrides
00:01 +8: ElementShadowSection reset clears the shadow config instead of disabling it
00:01 +9: ElementShadowSection changing profile updates shadowProfileId
00:01 +10: ElementShadowSection numeric fields update and clear nullable overrides
00:01 +11: ElementShadowSection invalid scale and opacity values are rejected
00:01 +12: ElementShadowSection footprint block is visible only for active shadows
00:01 +13: ElementShadowSection footprint null and partial values sync text fields
00:01 +14: ElementShadowSection footprint fields update ratios and preserve shadow fields
00:02 +15: ElementShadowSection invalid footprint values show errors and do not emit changes
00:02 +16: ElementShadowSection reset and clearing the last footprint field write null
00:02 +17: ElementShadowSection existing profile toggle and number changes preserve footprint
00:02 +18: ElementShadowSection missing profile is shown as a diagnostic
00:02 +19: ElementShadowSection profile none is informational and not an error
00:02 +20: ElementShadowSection forbidden V0 fields are not rendered
00:02 +21: All tests passed!
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

## 16. Ligne finale exacte des tests globaux cibles

### `flutter test test/application/shadow`

Resultat : exit code `0`.

Ligne finale exacte :

```text
00:00 +51: All tests passed!
```

### `flutter test test/features/tileset_library`

Resultat : exit code `0`.

Ligne finale exacte :

```text
00:02 +35: All tests passed!
```

### `flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette/widgets/shadow test/application/shadow test/features/tileset_library`

Resultat : exit code `0`.

Sortie :

```text
Analyzing 4 items...
No issues found! (ran in 2.2s)
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

## 17. Resultats des scans anti-derive

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

### Canvas

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

## 18. git status initial

Premier status verifiable dans cette reprise de session, avant creation du rapport :

```text
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
 M packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
```

Interpretation honnete : aucun fichier hors lot ni fichier non suivi preexistant n'est visible dans ce status. Les deux fichiers modifies correspondent au travail Shadow-31.

## 19. git status final

Status final attendu apres creation du rapport :

```text
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
 M packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
?? reports/shadows/shadow_lot_31_element_shadow_footprint_ui.md
```

## 20. git diff --stat

Avant creation du rapport :

```text
 .../widgets/shadow/element_shadow_section.dart     | 268 ++++++++++++++++++++
 .../element_shadow_section_test.dart               | 275 +++++++++++++++++++++
 2 files changed, 543 insertions(+)
```

## 21. Non-objectifs respectes

- Aucun runtime modifie.
- Aucun canvas/painter modifie.
- Aucun modele/core codec modifie.
- Aucun Shadow Studio cree.
- Aucune lumiere globale creee.
- Aucun build_runner lance.
- Aucun commit effectue.

## 22. Risques / reserves

- Le bloc footprint ajoute de la hauteur a `ElementShadowSection`. Il reste compact en grille 2x2, mais une future passe UX pourra peut-etre regrouper les champs si le panneau devient dense.
- Les messages d'erreur sont volontairement courts. Ils couvrent les contraintes V0 sans ajouter d'aide avancee.
- Les champs acceptent `-` et `.` via l'input formatter existant, puis la validation rejette les formes non numeriques.

## 23. Auto-review finale

- Ai-je ajoute l'UI footprint au niveau element ? oui.
- Ai-je evite de toucher au runtime ? oui.
- Ai-je evite de toucher a la preview canvas ? oui.
- Ai-je evite de modifier les modeles/codecs core ? oui.
- Ai-je conserve `shadowProfileId` ? oui.
- Ai-je conserve `castsShadow` ? oui.
- Ai-je conserve `offset/scale/opacity` ? oui.
- Ai-je valide les anchors dans `0..1` ? oui.
- Ai-je valide footprint width/height `> 0` ? oui.
- Ai-je represente reset par `footprint null` ? oui.
- Ai-je evite de creer une lumiere globale ? oui.

## 24. Regard critique sur le prompt

Le prompt est coherent avec la trajectoire Shadow-27 a Shadow-30. Le point le plus sensible etait la conservation de `footprint` dans les mutations existantes, car `_setProfile`, `_setNumber` et `_setCastsShadow` reconstruisaient deja des configs completes. Les tests ajoutent une regression explicite pour ce risque.

## 25. Contenu complet des fichiers crees/modifies

Les deux fichiers modifies sont longs :

- `element_shadow_section.dart` : 848 lignes.
- `element_shadow_section_test.dart` : 792 lignes.

Les sections modifiees completes sont reproduites ci-dessous avec leurs lignes, puis le diff complet du lot est inclus en section 26.

### Sections modifiees de `element_shadow_section.dart`

```text
35-42   controllers et erreurs footprint
53-57   initialisation des controllers footprint
75-78   dispose des controllers footprint
206-212 insertion du bloc Empreinte au sol
221-224 reset global qui vide aussi les erreurs footprint
314-425 widgets _footprintSection et _footprintField
466-589 mutations preservant ou ecrivant footprint
616-640 validation footprint
642-654 synchronisation des controllers footprint
672-745 helpers footprint
```

### Sections modifiees de `element_shadow_section_test.dart`

```text
358-624 tests widget footprint
693-698 helper _fieldText
```

## 26. Diffs complets ou equivalence /dev/null pour fichiers crees

### Diff des fichiers modifies

```diff
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
index 20609b7e..8e900adc 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
@@ -32,8 +32,14 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
   late final TextEditingController _scaleXController;
   late final TextEditingController _scaleYController;
   late final TextEditingController _opacityController;
+  late final TextEditingController _footprintAnchorXController;
+  late final TextEditingController _footprintAnchorYController;
+  late final TextEditingController _footprintWidthController;
+  late final TextEditingController _footprintHeightController;
   final Map<_ShadowNumberField, String> _errors =
       <_ShadowNumberField, String>{};
+  final Map<_ShadowFootprintField, String> _footprintErrors =
+      <_ShadowFootprintField, String>{};
   String? _activationMessage;
 
   @override
@@ -44,6 +50,10 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
     _scaleXController = TextEditingController();
     _scaleYController = TextEditingController();
     _opacityController = TextEditingController();
+    _footprintAnchorXController = TextEditingController();
+    _footprintAnchorYController = TextEditingController();
+    _footprintWidthController = TextEditingController();
+    _footprintHeightController = TextEditingController();
     _syncControllers(widget.shadow);
   }
 
@@ -62,6 +72,10 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
     _scaleXController.dispose();
     _scaleYController.dispose();
     _opacityController.dispose();
+    _footprintAnchorXController.dispose();
+    _footprintAnchorYController.dispose();
+    _footprintWidthController.dispose();
+    _footprintHeightController.dispose();
     super.dispose();
   }
 
@@ -191,6 +205,10 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
           ),
           if (shadow != null) ...[
             const SizedBox(height: 10),
+            if (shadow.castsShadow) ...[
+              _footprintSection(context),
+              const SizedBox(height: 10),
+            ],
             _numberGrid(context),
             const SizedBox(height: 10),
             Align(
@@ -202,6 +220,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
                 onPressed: () {
                   setState(() {
                     _errors.clear();
+                    _footprintErrors.clear();
                     _activationMessage = null;
                   });
                   widget.onChanged(null);
@@ -292,6 +311,119 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
     );
   }
 
+  Widget _footprintSection(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final hasFootprint = widget.shadow?.footprint != null;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Empreinte au sol',
+          style: TextStyle(
+            color: label,
+            fontSize: 11,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          'Ajuste la base utilisée pour calculer l’ombre de cet élément. Les instances peuvent encore la personnaliser.',
+          style: TextStyle(color: secondary, fontSize: 10),
+        ),
+        const SizedBox(height: 8),
+        Row(
+          children: [
+            Expanded(
+              child: _footprintField(
+                context,
+                _ShadowFootprintField.anchorX,
+              ),
+            ),
+            const SizedBox(width: 8),
+            Expanded(
+              child: _footprintField(
+                context,
+                _ShadowFootprintField.anchorY,
+              ),
+            ),
+          ],
+        ),
+        const SizedBox(height: 8),
+        Row(
+          children: [
+            Expanded(
+              child: _footprintField(
+                context,
+                _ShadowFootprintField.width,
+              ),
+            ),
+            const SizedBox(width: 8),
+            Expanded(
+              child: _footprintField(
+                context,
+                _ShadowFootprintField.height,
+              ),
+            ),
+          ],
+        ),
+        if (hasFootprint) ...[
+          const SizedBox(height: 8),
+          Align(
+            alignment: Alignment.centerLeft,
+            child: PushButton(
+              key: const ValueKey('element-shadow-footprint-reset-button'),
+              controlSize: ControlSize.small,
+              secondary: true,
+              onPressed: _resetFootprint,
+              child: const Text('Réinitialiser l’empreinte'),
+            ),
+          ),
+        ],
+      ],
+    );
+  }
+
+  Widget _footprintField(BuildContext context, _ShadowFootprintField field) {
+    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
+    final error = _footprintErrors[field];
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          field.label,
+          style: TextStyle(color: secondary, fontSize: 10),
+        ),
+        const SizedBox(height: 4),
+        MacosTextField(
+          key: ValueKey('element-shadow-footprint-${field.keyName}-field'),
+          controller: _footprintControllerFor(field),
+          enabled: widget.shadow?.castsShadow == true,
+          placeholder: 'auto',
+          keyboardType: const TextInputType.numberWithOptions(
+            signed: true,
+            decimal: true,
+          ),
+          inputFormatters: <TextInputFormatter>[
+            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
+          ],
+          onChanged: (value) => _setFootprintNumber(field, value),
+        ),
+        if (error != null) ...[
+          const SizedBox(height: 3),
+          Text(
+            error,
+            style: TextStyle(
+              color: CupertinoColors.systemRed.resolveFrom(context),
+              fontSize: 10,
+            ),
+          ),
+        ],
+      ],
+    );
+  }
+
   Widget _numberField(BuildContext context, _ShadowNumberField field) {
     final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
     final error = _errors[field];
@@ -344,6 +476,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
           scaleX: current.scaleX,
           scaleY: current.scaleY,
           opacity: current.opacity,
+          footprint: current.footprint,
         ),
       );
       return;
@@ -374,6 +507,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
         scaleX: current?.scaleX,
         scaleY: current?.scaleY,
         opacity: current?.opacity,
+        footprint: current?.footprint,
       ),
     );
   }
@@ -389,6 +523,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
         scaleX: current?.scaleX,
         scaleY: current?.scaleY,
         opacity: current?.opacity,
+        footprint: current?.footprint,
       ),
     );
   }
@@ -408,6 +543,47 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
         scaleX: field == _ShadowNumberField.scaleX ? value : current.scaleX,
         scaleY: field == _ShadowNumberField.scaleY ? value : current.scaleY,
         opacity: field == _ShadowNumberField.opacity ? value : current.opacity,
+        footprint: current.footprint,
+      ),
+    );
+  }
+
+  void _setFootprintNumber(_ShadowFootprintField field, String rawValue) {
+    final current = widget.shadow;
+    if (current == null) return;
+    final value = _parseFootprintNumber(field, rawValue);
+    if (value?.isNaN == true) return;
+    widget.onChanged(
+      ProjectElementShadowConfig(
+        castsShadow: current.castsShadow,
+        shadowProfileId: current.shadowProfileId,
+        offsetX: current.offsetX,
+        offsetY: current.offsetY,
+        scaleX: current.scaleX,
+        scaleY: current.scaleY,
+        opacity: current.opacity,
+        footprint: _updatedFootprint(
+          current.footprint,
+          field: field,
+          value: value,
+        ),
+      ),
+    );
+  }
+
+  void _resetFootprint() {
+    final current = widget.shadow;
+    if (current == null) return;
+    setState(_footprintErrors.clear);
+    widget.onChanged(
+      ProjectElementShadowConfig(
+        castsShadow: current.castsShadow,
+        shadowProfileId: current.shadowProfileId,
+        offsetX: current.offsetX,
+        offsetY: current.offsetY,
+        scaleX: current.scaleX,
+        scaleY: current.scaleY,
+        opacity: current.opacity,
       ),
     );
   }
@@ -437,12 +613,45 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
     return parsed;
   }
 
+  double? _parseFootprintNumber(
+    _ShadowFootprintField field,
+    String rawValue,
+  ) {
+    final trimmed = rawValue.trim();
+    if (trimmed.isEmpty) {
+      setState(() => _footprintErrors.remove(field));
+      return null;
+    }
+    final parsed = double.tryParse(trimmed);
+    if (parsed == null || !parsed.isFinite) {
+      setState(() => _footprintErrors[field] = 'Nombre invalide');
+      return _invalidNumber;
+    }
+    if (field.isAnchor && (parsed < 0 || parsed > 1)) {
+      setState(() => _footprintErrors[field] = 'Doit être entre 0 et 1');
+      return _invalidNumber;
+    }
+    if (!field.isAnchor && parsed <= 0) {
+      setState(() => _footprintErrors[field] = 'Doit être > 0');
+      return _invalidNumber;
+    }
+    setState(() => _footprintErrors.remove(field));
+    return parsed;
+  }
+
   void _syncControllers(ProjectElementShadowConfig? shadow) {
     _offsetXController.text = _formatNumber(shadow?.offsetX);
     _offsetYController.text = _formatNumber(shadow?.offsetY);
     _scaleXController.text = _formatNumber(shadow?.scaleX);
     _scaleYController.text = _formatNumber(shadow?.scaleY);
     _opacityController.text = _formatNumber(shadow?.opacity);
+    final footprint = shadow?.footprint;
+    _footprintAnchorXController.text = _formatNumber(footprint?.anchorXRatio);
+    _footprintAnchorYController.text = _formatNumber(footprint?.anchorYRatio);
+    _footprintWidthController.text =
+        _formatNumber(footprint?.footprintWidthRatio);
+    _footprintHeightController.text =
+        _formatNumber(footprint?.footprintHeightRatio);
   }
 
   TextEditingController _controllerFor(_ShadowNumberField field) {
@@ -459,6 +668,21 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
         return _opacityController;
     }
   }
+
+  TextEditingController _footprintControllerFor(
+    _ShadowFootprintField field,
+  ) {
+    switch (field) {
+      case _ShadowFootprintField.anchorX:
+        return _footprintAnchorXController;
+      case _ShadowFootprintField.anchorY:
+        return _footprintAnchorYController;
+      case _ShadowFootprintField.width:
+        return _footprintWidthController;
+      case _ShadowFootprintField.height:
+        return _footprintHeightController;
+    }
+  }
 }
 
 const double _invalidNumber = double.nan;
@@ -476,6 +700,50 @@ enum _ShadowNumberField {
   final String label;
 }
 
+enum _ShadowFootprintField {
+  anchorX('anchorX', 'Ancre X'),
+  anchorY('anchorY', 'Ancre Y'),
+  width('width', 'Largeur d’empreinte'),
+  height('height', 'Hauteur d’empreinte');
+
+  const _ShadowFootprintField(this.keyName, this.label);
+
+  final String keyName;
+  final String label;
+
+  bool get isAnchor =>
+      this == _ShadowFootprintField.anchorX ||
+      this == _ShadowFootprintField.anchorY;
+}
+
+StaticShadowFootprintConfig? _updatedFootprint(
+  StaticShadowFootprintConfig? current, {
+  required _ShadowFootprintField field,
+  required double? value,
+}) {
+  final anchorX =
+      field == _ShadowFootprintField.anchorX ? value : current?.anchorXRatio;
+  final anchorY =
+      field == _ShadowFootprintField.anchorY ? value : current?.anchorYRatio;
+  final width = field == _ShadowFootprintField.width
+      ? value
+      : current?.footprintWidthRatio;
+  final height = field == _ShadowFootprintField.height
+      ? value
+      : current?.footprintHeightRatio;
+
+  if (anchorX == null && anchorY == null && width == null && height == null) {
+    return null;
+  }
+
+  return StaticShadowFootprintConfig(
+    anchorXRatio: anchorX,
+    anchorYRatio: anchorY,
+    footprintWidthRatio: width,
+    footprintHeightRatio: height,
+  );
+}
+
 String _statusLabel(ElementShadowReadStatus status) {
   switch (status) {
     case ElementShadowReadStatus.notConfigured:
diff --git a/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart b/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
index 5d2ee02e..aad31388 100644
--- a/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
+++ b/packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
@@ -355,6 +355,274 @@ void main() {
       expect(harness.shadow!.opacity, 0.5);
     });
 
+    testWidgets('footprint block is visible only for active shadows',
+        (tester) async {
+      final activeHarness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'tree_large',
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: activeHarness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      expect(find.text('Empreinte au sol'), findsOneWidget);
+
+      final nullHarness = _ShadowSectionHarness();
+      await _pumpSection(
+        tester,
+        harness: nullHarness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      expect(find.text('Empreinte au sol'), findsNothing);
+
+      final disabledHarness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: false,
+          shadowProfileId: 'tree_large',
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: disabledHarness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      expect(find.text('Empreinte au sol'), findsNothing);
+    });
+
+    testWidgets('footprint null and partial values sync text fields',
+        (tester) async {
+      final emptyHarness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'tree_large',
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: emptyHarness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      expect(_fieldText(tester, 'element-shadow-footprint-anchorX-field'), '');
+      expect(_fieldText(tester, 'element-shadow-footprint-anchorY-field'), '');
+      expect(_fieldText(tester, 'element-shadow-footprint-width-field'), '');
+      expect(_fieldText(tester, 'element-shadow-footprint-height-field'), '');
+
+      final partialHarness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'tree_large',
+          footprint: StaticShadowFootprintConfig(
+            anchorXRatio: 0.25,
+            footprintWidthRatio: 0.5,
+          ),
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: partialHarness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      expect(
+        _fieldText(tester, 'element-shadow-footprint-anchorX-field'),
+        '0.25',
+      );
+      expect(_fieldText(tester, 'element-shadow-footprint-anchorY-field'), '');
+      expect(
+        _fieldText(tester, 'element-shadow-footprint-width-field'),
+        '0.5',
+      );
+      expect(_fieldText(tester, 'element-shadow-footprint-height-field'), '');
+    });
+
+    testWidgets('footprint fields update ratios and preserve shadow fields',
+        (tester) async {
+      final harness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'tree_large',
+          offsetX: 1,
+          offsetY: 2,
+          scaleX: 1.2,
+          scaleY: 0.8,
+          opacity: 0.4,
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-anchorX-field')),
+        '0.25',
+      );
+      await tester.pump();
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-anchorY-field')),
+        '0.75',
+      );
+      await tester.pump();
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-width-field')),
+        '0.5',
+      );
+      await tester.pump();
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-height-field')),
+        '0.125',
+      );
+      await tester.pump();
+
+      final shadow = harness.shadow!;
+      expect(shadow.castsShadow, isTrue);
+      expect(shadow.shadowProfileId, 'tree_large');
+      expect(shadow.offsetX, 1);
+      expect(shadow.offsetY, 2);
+      expect(shadow.scaleX, 1.2);
+      expect(shadow.scaleY, 0.8);
+      expect(shadow.opacity, 0.4);
+      expect(shadow.footprint!.anchorXRatio, 0.25);
+      expect(shadow.footprint!.anchorYRatio, 0.75);
+      expect(shadow.footprint!.footprintWidthRatio, 0.5);
+      expect(shadow.footprint!.footprintHeightRatio, 0.125);
+    });
+
+    testWidgets('invalid footprint values show errors and do not emit changes',
+        (tester) async {
+      final initial = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        footprint: StaticShadowFootprintConfig(
+          anchorXRatio: 0.5,
+          footprintWidthRatio: 0.75,
+        ),
+      );
+      final harness = _ShadowSectionHarness(initial);
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+      harness.changes.clear();
+
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-anchorX-field')),
+        '2',
+      );
+      await tester.pump();
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-width-field')),
+        '0',
+      );
+      await tester.pump();
+
+      expect(find.text('Doit être entre 0 et 1'), findsOneWidget);
+      expect(find.text('Doit être > 0'), findsOneWidget);
+      expect(harness.shadow, initial);
+      expect(harness.changes, isEmpty);
+    });
+
+    testWidgets('reset and clearing the last footprint field write null',
+        (tester) async {
+      final harness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'tree_large',
+          footprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-footprint-anchorX-field')),
+        '',
+      );
+      await tester.pump();
+
+      expect(harness.shadow!.footprint, isNull);
+
+      harness.shadow = ProjectElementShadowConfig(
+        castsShadow: true,
+        shadowProfileId: 'tree_large',
+        footprint: StaticShadowFootprintConfig(anchorXRatio: 0.25),
+      );
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(_catalog([_profile('tree_large')])),
+      );
+
+      await tester.tap(
+        find.byKey(const ValueKey('element-shadow-footprint-reset-button')),
+      );
+      await tester.pump();
+
+      expect(harness.shadow!.footprint, isNull);
+      expect(harness.changes.last!.footprint, isNull);
+    });
+
+    testWidgets('existing profile toggle and number changes preserve footprint',
+        (tester) async {
+      final footprint = StaticShadowFootprintConfig(
+        anchorXRatio: 0.25,
+        anchorYRatio: 0.75,
+        footprintWidthRatio: 0.5,
+        footprintHeightRatio: 0.125,
+      );
+      final harness = _ShadowSectionHarness(
+        ProjectElementShadowConfig(
+          castsShadow: true,
+          shadowProfileId: 'tree_large',
+          offsetX: 4,
+          footprint: footprint,
+        ),
+      );
+      await _pumpSection(
+        tester,
+        harness: harness,
+        manifest: _project(
+          _catalog([_profile('tree_large'), _profile('rock_small')]),
+        ),
+      );
+
+      final popup = tester.widget<MacosPopupButton<String>>(
+        find.byKey(const ValueKey('element-shadow-profile-popup')),
+      );
+      popup.onChanged!('rock_small');
+      await tester.pump();
+      expect(harness.shadow!.shadowProfileId, 'rock_small');
+      expect(harness.shadow!.footprint, footprint);
+
+      await tester.enterText(
+        find.byKey(const ValueKey('element-shadow-offsetX-field')),
+        '3.5',
+      );
+      await tester.pump();
+      expect(harness.shadow!.offsetX, 3.5);
+      expect(harness.shadow!.footprint, footprint);
+
+      final toggle = tester.widget<CupertinoSwitch>(
+        find.byKey(const ValueKey('element-shadow-casts-switch')),
+      );
+      toggle.onChanged!(false);
+      await tester.pump();
+      expect(harness.shadow!.castsShadow, isFalse);
+      expect(harness.shadow!.footprint, footprint);
+    });
+
     testWidgets('missing profile is shown as a diagnostic', (tester) async {
       final harness = _ShadowSectionHarness(
         ProjectElementShadowConfig(
@@ -422,6 +690,13 @@ void main() {
   });
 }
 
+String _fieldText(WidgetTester tester, String keyName) {
+  return tester
+      .widget<MacosTextField>(find.byKey(ValueKey(keyName)))
+      .controller!
+      .text;
+}
+
 Future<void> _pumpSection(
   WidgetTester tester, {
   required _ShadowSectionHarness harness,
```

### Contenu du fichier cree `/dev/null -> reports/shadows/shadow_lot_31_element_shadow_footprint_ui.md`

Ce rapport constitue le fichier cree du lot. Son contenu est le present document.
