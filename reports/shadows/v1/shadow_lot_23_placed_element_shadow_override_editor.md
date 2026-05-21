# Shadow Lot 23 — Placed Element Shadow Override Editor V0

## 1. Résumé du lot

Shadow-23 ajoute l’édition de `MapPlacedElement.shadowOverride` pour une instance placée dans l’éditeur.

Le lot ajoute :

- une opération pure `setMapPlacedElementShadowOverride(...)` côté `map_core` ;
- un setter `EditorNotifier.setPlacedElementInstanceShadowOverride(...)` qui passe par `_applyMapMutation(...)` ;
- un read model léger pour l’override d’ombre d’instance ;
- un widget `PlacedElementShadowOverrideSection` dans la section des instances placées ;
- des tests core, read model, widget et notifier.

Le lot ne modifie pas le runtime, ne modifie pas `ProjectElementEntry.shadow`, ne crée pas de Shadow Studio et ne change aucun modèle persistant.

## 2. Design retenu

Le design retenu sépare les responsabilités :

- `map_core` porte l’opération pure de remplacement d’override sur une instance ciblée ;
- `map_editor` construit un read model UI sans résoudre le rendu runtime ;
- `EditorNotifier` applique la mutation de map via le flux existant `_applyMapMutation(...)` ;
- `PlacedInstancesSection` affiche la section sous l’opacité et avant animation / behaviors ;
- `PlacedElementShadowOverrideSection` ne modifie que la valeur transmise via callback.

L’héritage est représenté par `shadowOverride == null`. Un override explicite `ShadowOverrideMode.inherit` est accepté en lecture comme mode “Hériter”, mais l’action reset écrit `null`.

## 3. Fichiers créés

- `packages/map_core/test/shadow/map_placed_element_shadow_override_operation_test.dart`
- `packages/map_editor/lib/src/application/shadow/placed_element_shadow_override_read_model.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart`
- `packages/map_editor/test/application/shadow/placed_element_shadow_override_read_model_test.dart`
- `packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart`
- `reports/shadows/shadow_lot_23_placed_element_shadow_override_editor.md`

## 4. Fichiers modifiés

- `packages/map_core/lib/src/operations/map_placed_elements.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/test/placed_element_instance_opacity_notifier_test.dart`

## 5. Fichiers non modifiés explicitement

Fichiers et packages volontairement non modifiés :

- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/**`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `MapLayersComponent`
- `PlayableMapGame`
- `RuntimeMapGame`
- `PlayerComponent`
- `OverworldActorComponent`
- `PlacedElementOcclusionPatchComponent`

## 6. UI ajoutée

Une section `Ombre de cette instance` est affichée pour l’instance placée sélectionnée.

Elle expose :

- mode `Hériter` ;
- mode `Désactiver` ;
- mode `Personnaliser` ;
- action `Réinitialiser l’override` ;
- dropdown de profil Shadow compatible ;
- option `Hériter du profil de l’élément` ;
- champs `Offset X`, `Offset Y`, `Scale X`, `Scale Y`, `Opacité` ;
- action `Ajouter les profils Shadow par défaut` quand aucun profil compatible n’existe.

La section est intégrée dans `PlacedInstancesSection`, sous l’opacité et avant l’animation / behaviors.

## 7. Read model / helpers ajoutés

`PlacedElementShadowOverrideReadModel` expose :

- `instanceId` ;
- mode UI courant ;
- override courant ;
- indicateur `usesNullInheritance` ;
- options de profils compatibles ;
- profil sélectionné ;
- label de profil sélectionné ;
- message sur l’ombre source ;
- message d’absence de profil compatible.

Le read model réutilise `buildShadowProfileOptionsForManifest(...)`, ce qui conserve la règle Shadow-22 :

```text
profile.renderPass == groundStatic
profile.mode != none
```

## 8. Flux de modification MapPlacedElement.shadowOverride

Flux retenu :

```text
PlacedElementShadowOverrideSection
→ callback onChanged
→ PlacedInstancesSection
→ TilesetPalettePanel
→ EditorNotifier.setPlacedElementInstanceShadowOverride(...)
→ setMapPlacedElementShadowOverride(...)
→ _applyMapMutation(...)
```

L’opération core :

- trim l’id ;
- rejette un id vide ;
- rejette un id inconnu ;
- remplace uniquement l’instance ciblée ;
- accepte `shadowOverride == null`.

## 9. Gestion dirty state

`EditorNotifier.setPlacedElementInstanceShadowOverride(...)` utilise `_applyMapMutation(...)`, comme les mutations d’opacité, animation et behaviors d’instances placées.

Les tests vérifient que l’état devient dirty après mutation.

Le flux de sauvegarde existant reste inchangé.

## 10. Règles de compatibilité profils

Les profils proposés dans le dropdown d’instance statique sont uniquement les profils :

```text
renderPass == ShadowRenderPass.groundStatic
mode != ShadowCasterMode.none
```

Conséquences :

- `actorContact` absent du dropdown ;
- `none` absent du dropdown ;
- `ellipse + groundStatic` accepté ;
- `contactBlob + groundStatic` accepté ;
- catalogue vide : message + action de seed Shadow-22.

## 11. Pourquoi ce lot ne modifie pas l’élément source

Shadow-23 vise l’instance placée, pas le modèle d’élément.

Les modifications écrivent uniquement dans :

```text
MapPlacedElement.shadowOverride
```

Les tests notifier vérifient que `ProjectElementEntry.shadow` reste inchangé.

## 12. Pourquoi ce lot ne touche pas au runtime

Le runtime consomme déjà `MapPlacedElement.shadowOverride` depuis les lots précédents.

Shadow-23 ajoute uniquement la surface d’édition de cette donnée côté `map_editor`, sans changer :

- renderer ;
- provider runtime ;
- collection runtime ;
- builders runtime ;
- Flame components.

## 13. Tests ajoutés

Tests core :

- `setMapPlacedElementShadowOverride(...)` met à jour seulement l’instance ciblée ;
- reset `null` efface seulement l’override ciblé ;
- id vide rejeté ;
- id inconnu rejeté.

Tests read model :

- `null` et `inherit` explicite lus comme héritage ;
- `disabled` et `custom` lus comme modes correspondants ;
- filtrage `actorContact` et `none` ;
- catalogue vide ;
- custom sans `shadowProfileId` ;
- élément source sans shadow config.

Tests widget :

- titre affiché ;
- mode hériter ;
- mode désactivé ;
- mode personnaliser ;
- reset vers `null` ;
- offset / scale / opacity ;
- scale invalide rejeté ;
- opacity invalide rejetée ;
- dropdown filtré ;
- action seed visible.

Tests notifier :

- override custom persisté ;
- reset `null` persisté ;
- autre instance inchangée ;
- `ProjectElementEntry.shadow` inchangé ;
- dirty state activé.

## 14. Commandes lancées

Commandes d’audit initial :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

Tests RED lancés avant production :

```bash
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_operation_test.dart
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_override_read_model_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart
cd packages/map_editor && flutter test test/placed_element_instance_opacity_notifier_test.dart
```

Formatage :

```bash
dart format packages/map_core/lib/src/operations/map_placed_elements.dart packages/map_core/test/shadow/map_placed_element_shadow_override_operation_test.dart packages/map_editor/lib/src/application/shadow/placed_element_shadow_override_read_model.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart packages/map_editor/test/application/shadow/placed_element_shadow_override_read_model_test.dart packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart packages/map_editor/test/placed_element_instance_opacity_notifier_test.dart
```

Tests ciblés GREEN :

```bash
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_operation_test.dart
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_override_read_model_test.dart
cd packages/map_editor && flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart
cd packages/map_editor && flutter test test/placed_element_instance_opacity_notifier_test.dart
```

Régressions ciblées :

```bash
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels lib/src/features/editor/state test/application/shadow test/features test/placed_element_instance_opacity_notifier_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow/placed_element_shadow_override_read_model.dart lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart lib/src/features/editor/state/editor_notifier.dart test/application/shadow/placed_element_shadow_override_read_model_test.dart test/features/tileset_library/placed_element_shadow_override_section_test.dart test/placed_element_instance_opacity_notifier_test.dart
cd packages/map_editor && flutter test
```

Vérifications anti-dérive :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models"
git diff -U0 -- packages/map_core packages/map_editor | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile"
git diff -U0 -- packages/map_editor | rg -n "actorContact"
rg -n "ShadowLayerComponent|Flame|Canvas|drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|zOrder|zIndex" packages/map_core packages/map_editor
rg -n "actorContact" packages/map_core/lib/src/operations packages/map_editor/lib/src/application/shadow packages/map_editor/lib/src/ui/panels/tileset_palette
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Résultats complets des tests ciblés

### Core operation

Commande :

```bash
cd packages/map_core && dart test test/shadow/map_placed_element_shadow_override_operation_test.dart
```

Sortie utile complète :

```text
00:00 +0: loading test/shadow/map_placed_element_shadow_override_operation_test.dart
00:00 +0: setMapPlacedElementShadowOverride updates only the targeted placed element
00:00 +1: setMapPlacedElementShadowOverride reset with null clears only the targeted override
00:00 +2: setMapPlacedElementShadowOverride rejects empty instance id
00:00 +3: setMapPlacedElementShadowOverride rejects unknown instance id
00:00 +4: All tests passed!
```

### Read model

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/placed_element_shadow_override_read_model_test.dart
```

Sortie utile complète :

```text
00:00 +0: loading test/application/shadow/placed_element_shadow_override_read_model_test.dart
00:00 +0: buildPlacedElementShadowOverrideReadModel null and explicit inherit override map to inherit mode
00:00 +1: buildPlacedElementShadowOverrideReadModel disabled and custom override map to matching modes
00:00 +2: buildPlacedElementShadowOverrideReadModel filters actorContact and none profiles from static instance options
00:00 +3: buildPlacedElementShadowOverrideReadModel empty catalog reports no compatible profiles
00:00 +4: buildPlacedElementShadowOverrideReadModel custom without shadowProfileId inherits source profile
00:00 +5: buildPlacedElementShadowOverrideReadModel source element without shadow config exposes an informative message
00:00 +6: All tests passed!
```

### Widget section

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library/placed_element_shadow_override_section_test.dart
```

Sortie utile complète :

```text
00:00 +0: loading test/features/tileset_library/placed_element_shadow_override_section_test.dart
00:01 +0: PlacedElementShadowOverrideSection shows the section title and inherit mode for null override
00:01 +1: PlacedElementShadowOverrideSection disabled mode emits a disabled override
00:01 +2: PlacedElementShadowOverrideSection custom mode emits custom override and reset emits null
00:01 +3: PlacedElementShadowOverrideSection number fields update custom offset scale and opacity
00:01 +4: PlacedElementShadowOverrideSection invalid scale and opacity values do not emit changes
00:01 +5: PlacedElementShadowOverrideSection profile dropdown filters actorContact and none profiles
00:01 +6: PlacedElementShadowOverrideSection empty catalog shows seed action
00:01 +7: All tests passed!
```

### Notifier

Commande :

```bash
cd packages/map_editor && flutter test test/placed_element_instance_opacity_notifier_test.dart
```

Sortie utile complète :

```text
00:00 +0: loading test/placed_element_instance_opacity_notifier_test.dart
00:00 +0: setPlacedElementInstanceOpacity updates the selected placed instance
00:00 +1: setPlacedElementInstanceShadowOverride updates only targeted instance
00:00 +2: setPlacedElementInstanceShadowOverride null resets the targeted instance
00:00 +3: All tests passed!
```

## 16. Ligne finale exacte des tests globaux ciblés

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final exact :

```text
00:00 +165: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Résultat final exact :

```text
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Résultat final exact :

```text
00:00 +34: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library
```

Résultat final exact :

```text
00:01 +25: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
```

Résultat final exact :

```text
00:00 +8: All tests passed!
```

Commande large demandée :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels lib/src/features/editor/state test/application/shadow test/features test/placed_element_instance_opacity_notifier_test.dart
```

Résultat final exact :

```text
14 issues found. (ran in 2.0s)
```

Détail utile des 14 issues : elles sont dans des fichiers non modifiés par Shadow-23 :

```text
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:807:13
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:815:13
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:891:15
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:901:17
info • Use 'const' with the constructor to improve performance • lib/src/ui/panels/character_library_panel.dart:1086:9
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:1131:7
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:1198:21
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:1221:21
info • 'minSize' is deprecated • lib/src/ui/panels/character_library_panel.dart:1283:11
info • Use 'const' with the constructor to improve performance • lib/src/ui/panels/element_collision_editor_sheet.dart:798:26
info • Use 'const' with the constructor to improve performance • lib/src/ui/panels/event_properties_panel.dart:337:11
info • 'minSize' is deprecated • lib/src/ui/panels/event_properties_panel.dart:675:19
info • Use 'const' for final variables initialized to a constant value • lib/src/ui/panels/event_properties_panel.dart:1000:5
info • 'minSize' is deprecated • lib/src/ui/panels/event_properties_panel.dart:1023:17
```

Commande ciblée sur les fichiers touchés :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow/placed_element_shadow_override_read_model.dart lib/src/ui/panels/tileset_palette_panel.dart lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart lib/src/features/editor/state/editor_notifier.dart test/application/shadow/placed_element_shadow_override_read_model_test.dart test/features/tileset_library/placed_element_shadow_override_section_test.dart test/placed_element_instance_opacity_notifier_test.dart
```

Résultat final exact :

```text
No issues found! (ran in 1.3s)
```

Commande complète éditeur :

```bash
cd packages/map_editor && flutter test
```

Résultat final exact :

```text
01:29 +1435 -45: Some tests failed.
```

Dette préexistante hors Shadow-23 observée pendant ce test complet :

- erreurs de compilation `Cannot invoke a non-'const' constructor where a const expression is expected` autour de `ProjectSurfaceCatalog()` dans de nombreux tests éditeur ;
- erreur shader `Asset 'shaders/ink_sparkle.frag' manifest could not be decoded: INVALID_ARGUMENT: Unsupported runtime stages format version. Expected 1, got 0.` ;
- tests environment studio en échec sur hit-test / clés absentes ;
- erreurs de symboles Pokémon converter manquants (`PokemonMoveAimedTarget`, `PokemonMoveFlags`, etc.) ;
- test de learnset avec move `protect` absent du catalogue local.

Les fichiers et tests Shadow-23 ciblés passent.

## 17. Résultats des scans anti-dérive

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff -U0 -- packages/map_core packages/map_editor | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "actorContact"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
rg -n "actorContact" packages/map_core/lib/src/operations packages/map_editor/lib/src/application/shadow packages/map_editor/lib/src/ui/panels/tileset_palette
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
rg -n "ShadowLayerComponent|Flame|Canvas|drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|zOrder|zIndex" packages/map_core packages/map_editor
```

Résultat :

```text
des occurrences préexistantes existent dans des rapports, tests et widgets canvas éditeur existants ; les scans diff-only ci-dessus confirment qu’aucune nouvelle occurrence Shadow-23 n’est ajoutée.
```

Commande :

```bash
git diff --check
```

Résultat :

```text
aucune ligne
```

## 18. git status initial

Statut initial avant les fichiers de production Shadow-23, après ajout RED des tests Shadow-23 :

```text
 M packages/map_editor/test/placed_element_instance_opacity_notifier_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_operation_test.dart
?? packages/map_editor/test/application/shadow/placed_element_shadow_override_read_model_test.dart
?? packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
```

Aucun fichier hors lot non suivi n’a été modifié par Shadow-23.

## 19. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final du lot avant le commit demandé après livraison :

```text
 M packages/map_core/lib/src/operations/map_placed_elements.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
 M packages/map_editor/test/placed_element_instance_opacity_notifier_test.dart
?? packages/map_core/test/shadow/map_placed_element_shadow_override_operation_test.dart
?? packages/map_editor/lib/src/application/shadow/placed_element_shadow_override_read_model.dart
?? packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart
?? packages/map_editor/test/application/shadow/placed_element_shadow_override_read_model_test.dart
?? packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart
?? reports/shadows/shadow_lot_23_placed_element_shadow_override_editor.md
```

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Résultat final :

```text
 .../lib/src/operations/map_placed_elements.dart    |  22 ++++
 .../src/features/editor/state/editor_notifier.dart |  39 +++++++
 .../placed_instances/placed_instances_section.dart |  22 ++++
 .../lib/src/ui/panels/tileset_palette_panel.dart   |  19 +++-
 ...ced_element_instance_opacity_notifier_test.dart | 123 +++++++++++++++++++++
 5 files changed, 221 insertions(+), 4 deletions(-)
```

`git diff --stat` liste uniquement les fichiers suivis modifiés. Les fichiers créés non suivis par Shadow-23 apparaissent dans le statut final ci-dessus.

## 21. Non-objectifs respectés

- Aucun runtime modifié.
- Aucun `map_gameplay` modifié.
- Aucun `map_battle` modifié.
- Aucun modèle persistant modifié.
- Aucun Shadow Studio créé.
- Aucun preview canvas Shadow créé.
- Aucun renderer modifié.
- Aucun Flame Component créé.
- Aucun build_runner lancé.
- Aucun `zOrder` / `zIndex`.
- Aucun blur runtime.
- Aucun atlas / sprite d’ombre.
- `ElementShadowSection` inchangé.

## 22. Risques / réserves

- L’UI V0 ne propose pas de preview canvas dédiée pour voir l’ombre pendant l’édition.
- Les champs numériques appliquent immédiatement les valeurs valides, sans bouton “appliquer”.
- Les valeurs vides signifient “ne pas override ce champ” côté `MapPlacedElementShadowOverride`.
- Le test complet `packages/map_editor && flutter test` reste rouge sur des dettes hors lot.
- Une vérification visuelle manuelle de l’inspector placé reste utile après lancement de l’app.

## 23. Auto-review finale

- Ai-je ajouté une UI pour `MapPlacedElement.shadowOverride` ? Oui.
- Ai-je évité de modifier `ProjectElementEntry.shadow` ? Oui.
- Ai-je permis inherit / disabled / custom ? Oui.
- Ai-je représenté “hériter” par `shadowOverride == null` autant que possible ? Oui.
- Ai-je filtré `actorContact` / `none` des profils disponibles ? Oui.
- Ai-je évité de toucher au runtime ? Oui.
- Ai-je évité de créer un Shadow Studio complet ? Oui.
- Ai-je respecté le dirty state existant ? Oui, via `_applyMapMutation(...)`.
- Ai-je évité de modifier plusieurs instances par erreur ? Oui, tests core et notifier.
- Ai-je documenté que ce lot aide à corriger taille/décalage instance par instance, mais ne crée pas encore de vraie direction globale de lumière ? Oui.

## 24. Regard critique sur le prompt

Le prompt est cohérent avec l’état des lots précédents. La seule zone lourde est l’exigence de tests widget + notifier + core + read model dans un seul lot, mais la découpe reste justifiée parce que la fonctionnalité touche le modèle, l’état et l’UI.

La contrainte “ne pas modifier ElementShadowSection” est saine : elle évite de mélanger l’ombre source et l’override instance.

## 25. Contenu complet des fichiers créés/modifiés

### Nouveau fichier : packages/map_core/test/shadow/map_placed_element_shadow_override_operation_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('setMapPlacedElementShadowOverride', () {
    test('updates only the targeted placed element', () {
      final override = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.disabled,
      );

      final updated = setMapPlacedElementShadowOverride(
        _baseMap(),
        instanceId: 'layer::1::1',
        shadowOverride: override,
      );

      expect(updated.placedElements.first.shadowOverride, override);
      expect(updated.placedElements.last.shadowOverride, isNull);
    });

    test('reset with null clears only the targeted override', () {
      final map = _baseMap().copyWith(
        placedElements: [
          _baseMap().placedElements.first.copyWith(
                shadowOverride: MapPlacedElementShadowOverride(
                  mode: ShadowOverrideMode.custom,
                  offsetX: 3,
                ),
              ),
          _baseMap().placedElements.last.copyWith(
                shadowOverride: MapPlacedElementShadowOverride(
                  mode: ShadowOverrideMode.disabled,
                ),
              ),
        ],
      );

      final updated = setMapPlacedElementShadowOverride(
        map,
        instanceId: 'layer::1::1',
        shadowOverride: null,
      );

      expect(updated.placedElements.first.shadowOverride, isNull);
      expect(
        updated.placedElements.last.shadowOverride,
        MapPlacedElementShadowOverride(mode: ShadowOverrideMode.disabled),
      );
    });

    test('rejects empty instance id', () {
      expect(
        () => setMapPlacedElementShadowOverride(
          _baseMap(),
          instanceId: ' ',
          shadowOverride: null,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects unknown instance id', () {
      expect(
        () => setMapPlacedElementShadowOverride(
          _baseMap(),
          instanceId: 'missing',
          shadowOverride: null,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _baseMap() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 4, height: 4),
    layers: [
      MapLayer.tile(
        id: 'layer',
        name: 'Layer',
        tilesetId: 'ts',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    placedElements: [
      MapPlacedElement(
        id: 'layer::1::1',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 1, y: 1),
      ),
      MapPlacedElement(
        id: 'layer::2::2',
        layerId: 'layer',
        elementId: 'lamp',
        pos: GridPos(x: 2, y: 2),
      ),
    ],
  );
}
```

### Nouveau fichier : packages/map_editor/lib/src/application/shadow/placed_element_shadow_override_read_model.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';

enum PlacedElementShadowOverrideUiMode {
  inherit,
  disabled,
  custom,
}

final class PlacedElementShadowOverrideReadModel {
  PlacedElementShadowOverrideReadModel({
    required this.instanceId,
    required this.mode,
    required this.override,
    required this.usesNullInheritance,
    required this.hasCompatibleProfiles,
    required List<ShadowProfileOptionReadModel> profileOptions,
    required this.selectedProfileId,
    required this.selectedProfileLabel,
    required this.sourceShadowMessage,
    required this.noCompatibleProfileMessage,
  }) : profileOptions =
            List<ShadowProfileOptionReadModel>.unmodifiable(profileOptions);

  final String instanceId;
  final PlacedElementShadowOverrideUiMode mode;
  final MapPlacedElementShadowOverride? override;
  final bool usesNullInheritance;
  final bool hasCompatibleProfiles;
  final List<ShadowProfileOptionReadModel> profileOptions;
  final String? selectedProfileId;
  final String selectedProfileLabel;
  final String? sourceShadowMessage;
  final String? noCompatibleProfileMessage;
}

PlacedElementShadowOverrideReadModel buildPlacedElementShadowOverrideReadModel({
  required ProjectManifest manifest,
  required ProjectElementEntry? element,
  required MapPlacedElement instance,
}) {
  final override = instance.shadowOverride;
  final profileOptions = buildShadowProfileOptionsForManifest(manifest);
  final mode = _overrideModeFor(override);
  final selectedProfileId = mode == PlacedElementShadowOverrideUiMode.custom
      ? override?.shadowProfileId
      : null;
  final selectedProfileLabel = _selectedProfileLabel(
    selectedProfileId,
    profileOptions,
  );

  return PlacedElementShadowOverrideReadModel(
    instanceId: instance.id,
    mode: mode,
    override: override,
    usesNullInheritance: override == null,
    hasCompatibleProfiles: profileOptions.isNotEmpty,
    profileOptions: profileOptions,
    selectedProfileId: selectedProfileId,
    selectedProfileLabel: selectedProfileLabel,
    sourceShadowMessage: _sourceShadowMessage(
      manifest: manifest,
      element: element,
    ),
    noCompatibleProfileMessage:
        profileOptions.isEmpty ? 'Aucun profil Shadow disponible.' : null,
  );
}

PlacedElementShadowOverrideUiMode _overrideModeFor(
  MapPlacedElementShadowOverride? override,
) {
  switch (override?.mode) {
    case null:
    case ShadowOverrideMode.inherit:
      return PlacedElementShadowOverrideUiMode.inherit;
    case ShadowOverrideMode.disabled:
      return PlacedElementShadowOverrideUiMode.disabled;
    case ShadowOverrideMode.custom:
      return PlacedElementShadowOverrideUiMode.custom;
  }
}

String _selectedProfileLabel(
  String? selectedProfileId,
  List<ShadowProfileOptionReadModel> profileOptions,
) {
  if (selectedProfileId == null) {
    return 'Profil de l’élément source';
  }
  for (final option in profileOptions) {
    if (option.id == selectedProfileId) {
      return option.label;
    }
  }
  return selectedProfileId;
}

String? _sourceShadowMessage({
  required ProjectManifest manifest,
  required ProjectElementEntry? element,
}) {
  if (element == null) {
    return 'Élément source introuvable.';
  }
  final shadow = element.shadow;
  if (shadow == null) {
    return 'L’élément source n’a pas d’ombre configurée.';
  }
  if (!shadow.castsShadow) {
    return 'L’ombre de l’élément source est désactivée.';
  }
  final profileId = shadow.shadowProfileId;
  if (profileId != null &&
      manifest.shadowCatalog.profileById(profileId) == null) {
    return 'Profil source introuvable : $profileId';
  }
  return null;
}
```

### Nouveau fichier : packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_override_read_model.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';

class PlacedElementShadowOverrideSection extends StatefulWidget {
  const PlacedElementShadowOverrideSection({
    super.key,
    required this.manifest,
    required this.element,
    required this.instance,
    required this.shadowOverride,
    required this.onChanged,
    required this.onEnsureDefaultShadowProfiles,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry? element;
  final MapPlacedElement instance;
  final MapPlacedElementShadowOverride? shadowOverride;
  final ValueChanged<MapPlacedElementShadowOverride?> onChanged;
  final VoidCallback onEnsureDefaultShadowProfiles;

  @override
  State<PlacedElementShadowOverrideSection> createState() =>
      _PlacedElementShadowOverrideSectionState();
}

class _PlacedElementShadowOverrideSectionState
    extends State<PlacedElementShadowOverrideSection> {
  late final TextEditingController _offsetXController;
  late final TextEditingController _offsetYController;
  late final TextEditingController _scaleXController;
  late final TextEditingController _scaleYController;
  late final TextEditingController _opacityController;
  final Map<_PlacedShadowNumberField, String> _errors =
      <_PlacedShadowNumberField, String>{};

  @override
  void initState() {
    super.initState();
    _offsetXController = TextEditingController();
    _offsetYController = TextEditingController();
    _scaleXController = TextEditingController();
    _scaleYController = TextEditingController();
    _opacityController = TextEditingController();
    _syncControllers(widget.shadowOverride);
  }

  @override
  void didUpdateWidget(covariant PlacedElementShadowOverrideSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shadowOverride != widget.shadowOverride) {
      _syncControllers(widget.shadowOverride);
    }
  }

  @override
  void dispose() {
    _offsetXController.dispose();
    _offsetYController.dispose();
    _scaleXController.dispose();
    _scaleYController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instance = widget.instance.copyWith(
      shadowOverride: widget.shadowOverride,
    );
    final readModel = buildPlacedElementShadowOverrideReadModel(
      manifest: widget.manifest,
      element: widget.element,
      instance: instance,
    );
    final label = EditorChrome.primaryLabel(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      key: const ValueKey('placed-shadow-override-section'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ombre de cette instance',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Modifie seulement cet élément placé, sans changer l’élément source.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          if (readModel.sourceShadowMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              readModel.sourceShadowMessage!,
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (readModel.noCompatibleProfileMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              readModel.noCompatibleProfileMessage!,
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                key: const ValueKey(
                  'placed-shadow-default-profiles-button',
                ),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: widget.onEnsureDefaultShadowProfiles,
                child: const Text('Ajouter les profils Shadow par défaut'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          CupertinoSlidingSegmentedControl<PlacedElementShadowOverrideUiMode>(
            groupValue: readModel.mode,
            children: const {
              PlacedElementShadowOverrideUiMode.inherit: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Hériter', style: TextStyle(fontSize: 10)),
              ),
              PlacedElementShadowOverrideUiMode.disabled: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Désactiver', style: TextStyle(fontSize: 10)),
              ),
              PlacedElementShadowOverrideUiMode.custom: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Personnaliser', style: TextStyle(fontSize: 10)),
              ),
            },
            onValueChanged: (mode) {
              if (mode == null) return;
              _setMode(mode);
            },
          ),
          const SizedBox(height: 8),
          _modeHelp(context, readModel.mode),
          if (readModel.mode == PlacedElementShadowOverrideUiMode.custom) ...[
            const SizedBox(height: 10),
            _profilePicker(
              context: context,
              profiles: readModel.profileOptions,
              selectedProfileId: readModel.selectedProfileId,
            ),
            const SizedBox(height: 10),
            _numberGrid(context),
          ],
          if (widget.shadowOverride != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                key: const ValueKey('placed-shadow-reset-button'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () {
                  setState(_errors.clear);
                  widget.onChanged(null);
                },
                child: const Text('Réinitialiser l’override'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeHelp(
    BuildContext context,
    PlacedElementShadowOverrideUiMode mode,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final message = switch (mode) {
      PlacedElementShadowOverrideUiMode.inherit =>
        'Cette instance utilise l’ombre configurée sur l’élément source.',
      PlacedElementShadowOverrideUiMode.disabled =>
        'Cette instance ne projettera aucune ombre.',
      PlacedElementShadowOverrideUiMode.custom =>
        'Cette instance personnalise son profil, son décalage, son échelle ou son opacité.',
    };
    return Text(
      message,
      style: TextStyle(color: secondary, fontSize: 10),
    );
  }

  Widget _profilePicker({
    required BuildContext context,
    required List<ShadowProfileOptionReadModel> profiles,
    required String? selectedProfileId,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final items = <MacosPopupMenuItem<String>>[
      const MacosPopupMenuItem<String>(
        value: _inheritProfileValue,
        child: Text('Hériter du profil de l’élément'),
      ),
      ...profiles.map(
        (profile) => MacosPopupMenuItem<String>(
          value: profile.id,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              '${profile.name} (${profile.id})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Shadow',
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        MacosPopupButton<String>(
          key: const ValueKey('placed-shadow-profile-popup'),
          items: items,
          value: selectedProfileId ?? _inheritProfileValue,
          onChanged: (profileId) {
            if (profileId == null) return;
            _setProfile(
              profileId == _inheritProfileValue ? null : profileId,
            );
          },
        ),
      ],
    );
  }

  Widget _numberGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.offsetX),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.offsetY),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.scaleX),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.scaleY),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _numberField(context, _PlacedShadowNumberField.opacity),
      ],
    );
  }

  Widget _numberField(
    BuildContext context,
    _PlacedShadowNumberField field,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final error = _errors[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        MacosTextField(
          key: ValueKey('placed-shadow-${field.keyName}-field'),
          controller: _controllerFor(field),
          placeholder: 'auto',
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          onChanged: (value) => _setNumber(field, value),
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

  void _setMode(PlacedElementShadowOverrideUiMode mode) {
    setState(_errors.clear);
    switch (mode) {
      case PlacedElementShadowOverrideUiMode.inherit:
        widget.onChanged(null);
      case PlacedElementShadowOverrideUiMode.disabled:
        widget.onChanged(
          MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        );
      case PlacedElementShadowOverrideUiMode.custom:
        widget.onChanged(_customOverride());
    }
  }

  void _setProfile(String? profileId) {
    widget.onChanged(
      _customOverride(shadowProfileId: profileId),
    );
  }

  void _setNumber(_PlacedShadowNumberField field, String rawValue) {
    final parsed = _parseNumber(field, rawValue);
    if (parsed?.isNaN == true) return;
    final current = _currentCustomOverride;
    widget.onChanged(
      _customOverride(
        offsetX: field == _PlacedShadowNumberField.offsetX
            ? parsed
            : current?.offsetX,
        offsetY: field == _PlacedShadowNumberField.offsetY
            ? parsed
            : current?.offsetY,
        scaleX:
            field == _PlacedShadowNumberField.scaleX ? parsed : current?.scaleX,
        scaleY:
            field == _PlacedShadowNumberField.scaleY ? parsed : current?.scaleY,
        opacity: field == _PlacedShadowNumberField.opacity
            ? parsed
            : current?.opacity,
      ),
    );
  }

  double? _parseNumber(_PlacedShadowNumberField field, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      setState(() => _errors.remove(field));
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) {
      setState(() => _errors[field] = 'Nombre invalide');
      return _invalidPlacedShadowNumber;
    }
    if ((field == _PlacedShadowNumberField.scaleX ||
            field == _PlacedShadowNumberField.scaleY) &&
        parsed <= 0) {
      setState(() => _errors[field] = 'Doit être > 0');
      return _invalidPlacedShadowNumber;
    }
    if (field == _PlacedShadowNumberField.opacity &&
        (parsed < 0 || parsed > 1)) {
      setState(() => _errors[field] = 'Doit être entre 0 et 1');
      return _invalidPlacedShadowNumber;
    }
    setState(() => _errors.remove(field));
    return parsed;
  }

  MapPlacedElementShadowOverride _customOverride({
    Object? shadowProfileId = _preservePlacedShadowValue,
    Object? offsetX = _preservePlacedShadowValue,
    Object? offsetY = _preservePlacedShadowValue,
    Object? scaleX = _preservePlacedShadowValue,
    Object? scaleY = _preservePlacedShadowValue,
    Object? opacity = _preservePlacedShadowValue,
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
    );
  }

  MapPlacedElementShadowOverride? get _currentCustomOverride {
    final current = widget.shadowOverride;
    if (current?.mode != ShadowOverrideMode.custom) {
      return null;
    }
    return current;
  }

  void _syncControllers(MapPlacedElementShadowOverride? override) {
    _offsetXController.text = _formatPlacedShadowNumber(override?.offsetX);
    _offsetYController.text = _formatPlacedShadowNumber(override?.offsetY);
    _scaleXController.text = _formatPlacedShadowNumber(override?.scaleX);
    _scaleYController.text = _formatPlacedShadowNumber(override?.scaleY);
    _opacityController.text = _formatPlacedShadowNumber(override?.opacity);
  }

  TextEditingController _controllerFor(_PlacedShadowNumberField field) {
    switch (field) {
      case _PlacedShadowNumberField.offsetX:
        return _offsetXController;
      case _PlacedShadowNumberField.offsetY:
        return _offsetYController;
      case _PlacedShadowNumberField.scaleX:
        return _scaleXController;
      case _PlacedShadowNumberField.scaleY:
        return _scaleYController;
      case _PlacedShadowNumberField.opacity:
        return _opacityController;
    }
  }
}

const String _inheritProfileValue = '__inherit__';
const double _invalidPlacedShadowNumber = double.nan;
const Object _preservePlacedShadowValue = Object();

enum _PlacedShadowNumberField {
  offsetX('offsetX', 'Offset X'),
  offsetY('offsetY', 'Offset Y'),
  scaleX('scaleX', 'Scale X'),
  scaleY('scaleY', 'Scale Y'),
  opacity('opacity', 'Opacité');

  const _PlacedShadowNumberField(this.keyName, this.label);

  final String keyName;
  final String label;
}

String _formatPlacedShadowNumber(double? value) {
  if (value == null) return '';
  return value.toString();
}
```

### Nouveau fichier : packages/map_editor/test/application/shadow/placed_element_shadow_override_read_model_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_override_read_model.dart';

void main() {
  group('buildPlacedElementShadowOverrideReadModel', () {
    test('null and explicit inherit override map to inherit mode', () {
      final nullModel = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(),
      );
      final explicitModel = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(),
        ),
      );

      expect(nullModel.mode, PlacedElementShadowOverrideUiMode.inherit);
      expect(explicitModel.mode, PlacedElementShadowOverrideUiMode.inherit);
      expect(nullModel.usesNullInheritance, isTrue);
      expect(explicitModel.usesNullInheritance, isFalse);
    });

    test('disabled and custom override map to matching modes', () {
      final disabled = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        ),
      );
      final custom = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            shadowProfileId: 'wide_shadow',
          ),
        ),
      );

      expect(disabled.mode, PlacedElementShadowOverrideUiMode.disabled);
      expect(custom.mode, PlacedElementShadowOverrideUiMode.custom);
      expect(custom.selectedProfileId, 'wide_shadow');
      expect(custom.selectedProfileLabel, 'Wide shadow');
    });

    test('filters actorContact and none profiles from static instance options',
        () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(
          catalog: ProjectShadowCatalog(
            profiles: [
              _profile('ground_shadow'),
              _profile(
                'actor_shadow',
                mode: ShadowCasterMode.contactBlob,
                renderPass: ShadowRenderPass.actorContact,
              ),
              _profile('none_shadow', mode: ShadowCasterMode.none),
            ],
          ),
        ),
        element: _element(),
        instance: _instance(),
      );

      expect(model.profileOptions.map((option) => option.id), [
        'ground_shadow',
      ]);
    });

    test('empty catalog reports no compatible profiles', () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(catalog: const ProjectShadowCatalog.empty()),
        element: _element(),
        instance: _instance(),
      );

      expect(model.profileOptions, isEmpty);
      expect(model.hasCompatibleProfiles, isFalse);
      expect(model.noCompatibleProfileMessage, isNotNull);
    });

    test('custom without shadowProfileId inherits source profile', () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _element(),
        instance: _instance(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 2,
          ),
        ),
      );

      expect(model.mode, PlacedElementShadowOverrideUiMode.custom);
      expect(model.selectedProfileId, isNull);
      expect(model.selectedProfileLabel, 'Profil de l’élément source');
    });

    test('source element without shadow config exposes an informative message',
        () {
      final model = buildPlacedElementShadowOverrideReadModel(
        manifest: _manifest(),
        element: _elementWithoutShadow(),
        instance: _instance(),
      );

      expect(model.sourceShadowMessage, isNotNull);
    });
  });
}

ProjectManifest _manifest({ProjectShadowCatalog? catalog}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [
            _profile('base_shadow', name: 'Base shadow'),
            _profile('wide_shadow', name: 'Wide shadow'),
          ],
        ),
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element({ProjectElementShadowConfig? shadow}) {
  return ProjectElementEntry(
    id: 'lamp',
    name: 'Lamp',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
    shadow: shadow ??
        ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'base_shadow',
        ),
  );
}

ProjectElementEntry _elementWithoutShadow() {
  return const ProjectElementEntry(
    id: 'lamp',
    name: 'Lamp',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}

MapPlacedElement _instance({MapPlacedElementShadowOverride? shadowOverride}) {
  return MapPlacedElement(
    id: 'layer::1::1',
    layerId: 'layer',
    elementId: 'lamp',
    pos: const GridPos(x: 1, y: 1),
    shadowOverride: shadowOverride,
  );
}

ProjectShadowProfile _profile(
  String id, {
  String? name,
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: name ?? '$id profile',
    mode: mode,
    renderPass: renderPass,
  );
}
```

### Nouveau fichier : packages/map_editor/test/features/tileset_library/placed_element_shadow_override_section_test.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart';

void main() {
  group('PlacedElementShadowOverrideSection', () {
    testWidgets('shows the section title and inherit mode for null override',
        (tester) async {
      final harness = _Harness();

      await _pumpSection(tester, harness: harness);

      expect(find.text('Ombre de cette instance'), findsOneWidget);
      expect(find.text('Hériter'), findsWidgets);
      expect(harness.value, isNull);
    });

    testWidgets('disabled mode emits a disabled override', (tester) async {
      final harness = _Harness();
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Désactiver'));
      await tester.pump();

      expect(harness.value, isNotNull);
      expect(harness.value!.mode, ShadowOverrideMode.disabled);
    });

    testWidgets('custom mode emits custom override and reset emits null',
        (tester) async {
      final harness = _Harness();
      await _pumpSection(tester, harness: harness);

      await tester.tap(find.text('Personnaliser'));
      await tester.pump();

      expect(harness.value!.mode, ShadowOverrideMode.custom);

      await tester
          .tap(find.byKey(const ValueKey('placed-shadow-reset-button')));
      await tester.pump();

      expect(harness.value, isNull);
    });

    testWidgets('number fields update custom offset scale and opacity',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
      );
      await _pumpSection(tester, harness: harness);

      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-offsetX-field')),
        '4',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-scaleX-field')),
        '1.5',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-opacity-field')),
        '0.25',
      );
      await tester.pump();

      expect(harness.value!.offsetX, 4);
      expect(harness.value!.scaleX, 1.5);
      expect(harness.value!.opacity, 0.25);
    });

    testWidgets('invalid scale and opacity values do not emit changes',
        (tester) async {
      final initial = MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        scaleX: 1,
        opacity: 0.5,
      );
      final harness = _Harness(value: initial);
      await _pumpSection(tester, harness: harness);

      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-scaleX-field')),
        '0',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('placed-shadow-opacity-field')),
        '2',
      );
      await tester.pump();

      expect(harness.value, initial);
      expect(find.text('Doit être > 0'), findsOneWidget);
      expect(find.text('Doit être entre 0 et 1'), findsOneWidget);
    });

    testWidgets('profile dropdown filters actorContact and none profiles',
        (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
        manifest: _project(
          catalog: ProjectShadowCatalog(
            profiles: [
              _profile('ground_shadow', name: 'Ground shadow'),
              _profile(
                'actor_shadow',
                mode: ShadowCasterMode.contactBlob,
                renderPass: ShadowRenderPass.actorContact,
              ),
              _profile('none_shadow', mode: ShadowCasterMode.none),
            ],
          ),
        ),
      );
      await _pumpSection(tester, harness: harness);

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const ValueKey('placed-shadow-profile-popup')),
      );

      expect(popup.items!.map((item) => item.value), [
        '__inherit__',
        'ground_shadow',
      ]);
    });

    testWidgets('empty catalog shows seed action', (tester) async {
      final harness = _Harness(
        value: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.custom,
        ),
        manifest: _project(catalog: const ProjectShadowCatalog.empty()),
      );
      await _pumpSection(tester, harness: harness);

      expect(find.text('Aucun profil Shadow disponible.'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('placed-shadow-default-profiles-button')),
      );
      await tester.pump();

      expect(harness.seedCount, 1);
    });
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required _Harness harness,
}) async {
  await tester.binding.setSurfaceSize(const Size(520, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.light(),
      child: MaterialApp(
        home: CupertinoPageScaffold(
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 460,
                child: PlacedElementShadowOverrideSection(
                  manifest: harness.manifest,
                  element: harness.element,
                  instance: harness.instance,
                  shadowOverride: harness.value,
                  onChanged: (next) {
                    harness.changes.add(next);
                    setState(() => harness.value = next);
                  },
                  onEnsureDefaultShadowProfiles: () {
                    harness.seedCount += 1;
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

final class _Harness {
  _Harness({
    this.value,
    ProjectManifest? manifest,
  }) : manifest = manifest ?? _project();

  MapPlacedElementShadowOverride? value;
  final ProjectManifest manifest;
  final ProjectElementEntry element = _element();
  final MapPlacedElement instance = _instance();
  final List<MapPlacedElementShadowOverride?> changes = [];
  int seedCount = 0;
}

ProjectManifest _project({ProjectShadowCatalog? catalog}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    shadowCatalog: catalog ??
        ProjectShadowCatalog(
          profiles: [
            _profile('base_shadow', name: 'Base shadow'),
            _profile('wide_shadow', name: 'Wide shadow'),
          ],
        ),
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectElementEntry _element() {
  return ProjectElementEntry(
    id: 'lamp',
    name: 'Lamp',
    tilesetId: 'ts',
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
    shadow: ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'base_shadow',
    ),
  );
}

MapPlacedElement _instance() {
  return const MapPlacedElement(
    id: 'layer::1::1',
    layerId: 'layer',
    elementId: 'lamp',
    pos: GridPos(x: 1, y: 1),
  );
}

ProjectShadowProfile _profile(
  String id, {
  String? name,
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: name ?? '$id profile',
    mode: mode,
    renderPass: renderPass,
  );
}
```

### Fichier modifié : packages/map_core/lib/src/operations/map_placed_elements.dart

Fichier existant long : section modifiée complète.

```diff
 import '../exceptions/map_exceptions.dart';
 import '../models/geometry.dart';
 import '../models/map_data.dart';
+import '../models/shadow.dart';
```

```dart
MapData setMapPlacedElementShadowOverride(
  MapData map, {
  required String instanceId,
  required MapPlacedElementShadowOverride? shadowOverride,
}) {
  final normalizedId = instanceId.trim();
  if (normalizedId.isEmpty) {
    throw const ValidationException(
        'Placed element instance id cannot be empty');
  }
  final index =
      map.placedElements.indexWhere((entry) => entry.id == normalizedId);
  if (index < 0) {
    throw ValidationException(
        'Placed element instance not found: $normalizedId');
  }
  final next = List<MapPlacedElement>.from(map.placedElements, growable: true);
  next[index] = next[index].copyWith(shadowOverride: shadowOverride);
  return map.copyWith(placedElements: next);
}
```

### Fichier modifié : packages/map_editor/lib/src/features/editor/state/editor_notifier.dart

Fichier existant long : section modifiée complète.

```dart
  void setPlacedElementInstanceShadowOverride({
    required String instanceId,
    required MapPlacedElementShadowOverride? shadowOverride,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.shadowOverride == shadowOverride) {
      return;
    }
    final updatedMap = setMapPlacedElementShadowOverride(
      map,
      instanceId: trimmedId,
      shadowOverride: shadowOverride,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: shadowOverride == null
          ? 'Override d’ombre réinitialisé pour ${previous.elementId}'
          : 'Override d’ombre mis à jour pour ${previous.elementId}',
    );
  }
```

### Fichier modifié : packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart

Fichier existant long : sections modifiées complètes.

```dart
class _PlacedElementInstanceVm {
  const _PlacedElementInstanceVm({
    required this.instance,
    required this.element,
    required this.selected,
  });

  final MapPlacedElement instance;
  final ProjectElementEntry? element;
  final bool selected;

  String get instanceId => instance.id;
  String get elementId => instance.elementId;
  GridPos get pos => instance.pos;
  bool get collisionEnabled => instance.collisionEnabled;
  double get opacity => instance.opacity;
  MapPlacedElementAnimation? get animation => instance.animation;
  List<MapPlacedElementBehavior> get behaviors => instance.behaviors;
  MapPlacedElementShadowOverride? get shadowOverride => instance.shadowOverride;
  int get frameCount => element?.frames.length ?? 1;
  TilesetSourceRect get source =>
      element?.frames.primarySource ??
      const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1);
}
```

```dart
class _PlacedInstancesSection extends StatelessWidget {
  const _PlacedInstancesSection({
    required this.manifest,
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.instances,
    required this.selectionAccent,
    required this.onSelectInstance,
    required this.onCollisionAppliedChanged,
    required this.onOpacityChanged,
    required this.onShadowOverrideChanged,
    required this.onEnsureDefaultShadowProfiles,
    required this.onAnimationConfigChanged,
    required this.onBehaviorsChanged,
    required this.dialogues,
    required this.storyVariables,
    required this.onDeleteInstance,
  });

  final ProjectManifest manifest;
  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final List<_PlacedElementInstanceVm> instances;
  final Color selectionAccent;
  final ValueChanged<_PlacedElementInstanceVm> onSelectInstance;
  final void Function(_PlacedElementInstanceVm instance, bool enabled)
      onCollisionAppliedChanged;
  final void Function(_PlacedElementInstanceVm instance, double opacity)
      onOpacityChanged;
  final void Function(
    _PlacedElementInstanceVm instance,
    MapPlacedElementShadowOverride? shadowOverride,
  ) onShadowOverrideChanged;
  final VoidCallback onEnsureDefaultShadowProfiles;
  final void Function(
    _PlacedElementInstanceVm instance,
    MapPlacedElementAnimation? animation,
  ) onAnimationConfigChanged;
  final void Function(
    _PlacedElementInstanceVm instance,
    List<MapPlacedElementBehavior> behaviors,
  ) onBehaviorsChanged;
  final List<ProjectDialogueEntry> dialogues;
  final List<ProjectStoryVariable> storyVariables;
  final ValueChanged<_PlacedElementInstanceVm> onDeleteInstance;
```

```dart
                _OpacitySliderRow(
                  value: selected.opacity,
                  onChanged: (value) => onOpacityChanged(selected, value),
                ),
                const SizedBox(height: 8),
                PlacedElementShadowOverrideSection(
                  manifest: manifest,
                  element: selected.element,
                  instance: selected.instance,
                  shadowOverride: selected.shadowOverride,
                  onChanged: (next) => onShadowOverrideChanged(
                    selected,
                    next,
                  ),
                  onEnsureDefaultShadowProfiles: onEnsureDefaultShadowProfiles,
                ),
                const SizedBox(height: 8),
                _PlacedElementAnimationSection(
```

### Fichier modifié : packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart

Fichier existant long : sections modifiées complètes.

```diff
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart';
 import 'package:map_editor/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart';
```

```dart
          _PlacedInstancesSection(
            manifest: project,
            image: image,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            instances: placedInstances,
            selectionAccent: tilesAccent,
            onSelectInstance: (instance) {
              notifier.selectPlacedElementInstance(instance.instanceId);
            },
            onCollisionAppliedChanged: (instance, enabled) {
              notifier.setPlacedElementInstanceCollisionEnabled(
                instanceId: instance.instanceId,
                enabled: enabled,
              );
            },
            onOpacityChanged: (instance, opacity) {
              notifier.setPlacedElementInstanceOpacity(
                instanceId: instance.instanceId,
                opacity: opacity,
              );
            },
            onShadowOverrideChanged: (instance, shadowOverride) {
              notifier.setPlacedElementInstanceShadowOverride(
                instanceId: instance.instanceId,
                shadowOverride: shadowOverride,
              );
            },
            onEnsureDefaultShadowProfiles: () {
              notifier.ensureDefaultShadowProfiles();
            },
            onAnimationConfigChanged: (instance, animation) {
```

### Fichier modifié : packages/map_editor/test/placed_element_instance_opacity_notifier_test.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('setPlacedElementInstanceOpacity updates the selected placed instance',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = const EditorState(
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tilesetId: 'ts',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'lamp',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
      activeLayerId: 'layer',
      selectedPlacedElementInstanceId: 'layer::1::1',
    );

    notifier.setPlacedElementInstanceOpacity(
      instanceId: 'layer::1::1',
      opacity: 0.55,
    );

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.single.opacity, 0.55);
    expect(state.selectedPlacedElementInstanceId, 'layer::1::1');
    expect(state.statusMessage, 'Opacité mise à jour pour lamp');
  });

  test('setPlacedElementInstanceShadowOverride updates only targeted instance',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final elementShadow = ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'base_shadow',
    );
    notifier.state = EditorState(
      project: ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        elements: [
          ProjectElementEntry(
            id: 'lamp',
            name: 'Lamp',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
            shadow: elementShadow,
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      ),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tilesetId: 'ts',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'lamp',
            pos: GridPos(x: 1, y: 1),
          ),
          MapPlacedElement(
            id: 'layer::2::2',
            layerId: 'layer',
            elementId: 'lamp',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      ),
      activeLayerId: 'layer',
      selectedPlacedElementInstanceId: 'layer::1::1',
    );

    final override = MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.custom,
      offsetX: 2,
      opacity: 0.4,
    );

    notifier.setPlacedElementInstanceShadowOverride(
      instanceId: 'layer::1::1',
      shadowOverride: override,
    );

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.first.shadowOverride, override);
    expect(state.activeMap!.placedElements.last.shadowOverride, isNull);
    expect(state.project!.elements.single.shadow, same(elementShadow));
    expect(state.isDirty, isTrue);
    expect(state.statusMessage, 'Override d’ombre mis à jour pour lamp');
  });

  test(
      'setPlacedElementInstanceShadowOverride null resets the targeted instance',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        layers: const [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tilesetId: 'ts',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'lamp',
            pos: const GridPos(x: 1, y: 1),
            shadowOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.disabled,
            ),
          ),
        ],
      ),
      activeLayerId: 'layer',
      selectedPlacedElementInstanceId: 'layer::1::1',
    );

    notifier.setPlacedElementInstanceShadowOverride(
      instanceId: 'layer::1::1',
      shadowOverride: null,
    );

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.single.shadowOverride, isNull);
    expect(state.statusMessage, 'Override d’ombre réinitialisé pour lamp');
  });
}
```

Le rapport courant est le fichier Markdown créé par ce lot. Son contenu est celui de ce document.

## 26. Diffs complets ou équivalents /dev/null pour fichiers créés

Pour les fichiers créés, les blocs complets en section 25 correspondent au contenu ajouté depuis un fichier vide.

Pour les fichiers existants modifiés, les sections modifiées complètes sont incluses en section 25, avec le contexte de méthode ou de widget concerné.
