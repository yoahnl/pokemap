# Shadow Lot 22 — Shadow Profile Catalog / Editor Availability V0

## 1. Résumé du lot

Shadow-22 ajoute une disponibilité explicite des profils Shadow côté éditeur.

Le lot ajoute des profils Shadow par défaut `groundStatic` côté `map_core`, filtre les options de profil d'ombre d'élément pour exclure `actorContact` et `none`, puis branche une action UI explicite "Ajouter les profils Shadow par défaut" dans `ElementShadowSection` via `EditorNotifier.ensureDefaultShadowProfiles()`.

Le lot ne modifie aucun fichier runtime. Il ne crée pas de Shadow Studio, ne crée pas de migration JSON incompatible, ne modifie pas `ProjectElementEntry.shadow` lors du seed et ne modifie aucun élément existant.

## 2. Design retenu

Design retenu :

- seed explicite depuis l'UI, sans auto-seed au chargement du projet ;
- opérations pures côté `map_core` pour créer, détecter et assurer les profils par défaut ;
- filtrage read model côté `map_editor` avec `renderPass == groundStatic && mode != none` ;
- action UI uniquement quand aucun profil compatible n'est disponible ;
- mutation du manifest via le flux existant `applyInMemoryProjectManifest(...)` ;
- aucun runtime modifié.

## 3. Fichiers créés

- `packages/map_core/lib/src/operations/default_shadow_profiles.dart`
- `packages/map_core/test/shadow/default_shadow_profiles_test.dart`
- `reports/shadows/shadow_lot_22_shadow_profile_catalog_editor_availability.md`

## 4. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart`
- `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`
- `packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart`

## 5. Fichiers non modifiés explicitement

- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/**`
- `ProjectElementEntry.shadow` model
- `ProjectManifest` model
- `ProjectShadowCatalog` model
- `MapLayersComponent`
- `PlayableMapGame`
- `RuntimeMapGame`
- `PlayerComponent`
- `OverworldActorComponent`
- `PlacedElementOcclusionPatchComponent`

Fichiers non suivis préexistants hors lot : aucun au démarrage de Shadow-22 selon `git status --short --untracked-files=all`.

État Git préexistant hors lot : la branche locale était déjà `ahead 1` par rapport à `origin/main`.

## 6. API core ajoutée

API exportée depuis `packages/map_core/lib/map_core.dart` :

```dart
List<ProjectShadowProfile> createDefaultGroundStaticShadowProfiles();
bool isGroundStaticElementShadowProfile(ProjectShadowProfile profile);
bool hasGroundStaticElementShadowProfiles(ProjectShadowCatalog catalog);
ProjectShadowCatalog ensureDefaultGroundStaticShadowProfiles(
  ProjectShadowCatalog catalog,
);
ProjectManifest ensureDefaultGroundStaticShadowProfilesForProject(
  ProjectManifest manifest,
);
```

## 7. Profils Shadow par défaut ajoutés

Profils ajoutés par `createDefaultGroundStaticShadowProfiles()` :

- `default-ground-soft-ellipse`
  - name: `Ombre douce au sol`
  - mode: `ShadowCasterMode.ellipse`
  - renderPass: `ShadowRenderPass.groundStatic`
  - opacity: `0.35`
  - colorHexRgb implicite: `000000`
  - softnessMode implicite: `hardEdge`

- `default-ground-wide-ellipse`
  - name: `Ombre large au sol`
  - mode: `ShadowCasterMode.ellipse`
  - renderPass: `ShadowRenderPass.groundStatic`
  - scaleX: `1.35`
  - scaleY: `0.85`
  - opacity: `0.28`
  - colorHexRgb implicite: `000000`
  - softnessMode implicite: `hardEdge`

- `default-ground-contact-blob`
  - name: `Ombre compacte au sol`
  - mode: `ShadowCasterMode.contactBlob`
  - renderPass: `ShadowRenderPass.groundStatic`
  - opacity: `0.35`
  - colorHexRgb implicite: `000000`
  - softnessMode implicite: `hardEdge`

Règles vérifiées :

- ids stables ;
- ids uniques ;
- uniquement `groundStatic` ;
- aucun `actorContact` ;
- aucun `none` ;
- hardEdge V0 ;
- pas de runtimeBlur ;
- pas de blurRadius ;
- pas de sprite/atlas.

## 8. Règles de compatibilité profil élément

Un profil compatible avec l'ombre d'un élément statique est défini par :

```text
profile.renderPass == ShadowRenderPass.groundStatic
profile.mode != ShadowCasterMode.none
```

Conséquences :

- un profil `actorContact` est absent du dropdown d'élément ;
- un profil `none` est absent du dropdown d'élément ;
- un catalogue contenant seulement `actorContact` est traité comme sans profil compatible ;
- un catalogue contenant seulement `none` est traité comme sans profil compatible ;
- un catalogue contenant un profil compatible existant n'est pas seedé automatiquement.

## 9. Comportement UI quand aucun profil compatible n'existe

`ElementShadowSection` affiche :

```text
Aucun profil Shadow disponible.
Ajoutez les profils par défaut pour commencer à configurer les ombres des éléments.
[Ajouter les profils Shadow par défaut]
```

Le dropdown inutilisable reste sans options compatibles. Le switch d'activation reste désactivé tant qu'aucun profil compatible n'existe.

## 10. Action “Ajouter les profils Shadow par défaut”

Le bouton appelle `onEnsureDefaultShadowProfiles`.

Le parent `TilesetPalettePanel` branche ce callback vers :

```dart
final updated = notifier.ensureDefaultShadowProfiles();
if (updated == null) return;
setStateDialog(() {
  shadowManifest = updated;
});
```

Après l'action, le dialog ouvert reçoit le manifest mis à jour et le dropdown affiche les profils par défaut.

## 11. Flux notifier/use case/dirty state

`EditorNotifier.ensureDefaultShadowProfiles()` :

- lit `state.project` ;
- applique `ensureDefaultGroundStaticShadowProfilesForProject(project)` ;
- si rien ne change, retourne le projet courant ;
- si le catalogue est seedé, appelle `applyInMemoryProjectManifest(...)` ;
- met `isProjectDirty` à `true` via le flux existant ;
- ne modifie aucun élément ;
- ne modifie pas `ProjectElementEntry.shadow`.

## 12. Pourquoi ce lot ne touche pas au runtime

Shadow-22 corrige l'availability editor du catalogue Shadow. Le runtime a déjà été traité dans les lots précédents :

- Shadow-17 : renderer intégré dans le pipeline runtime ;
- Shadow-18 : provider host ;
- Shadow-19 : actor contact shadows ;
- Shadow-21 : static placed element shadows visibles si configurées.

Ce lot ne modifie pas `packages/map_runtime/**` et ne change aucun renderer, provider runtime, resolver runtime ou composant Flame.

## 13. Limite volontaire / fausse attente évitée

Shadow-21 does not create or expose Shadow profiles in the editor. It only renders static placed element shadows at runtime when the project already contains a valid ProjectShadowCatalog and element/placement shadow configuration.

Shadow-22 ne rend pas les ombres runtime par lui-même. Il rend possible la création de profils par défaut dans l'éditeur afin que la configuration d'ombre d'élément puisse ensuite référencer un profil existant.

## 14. Pourquoi ce lot ne crée pas de Shadow Studio complet

Le besoin utilisateur immédiat est de sortir de l'état bloquant "Aucun profil Shadow disponible".

Shadow-22 ajoute donc seulement :

- profils par défaut stables ;
- action de seed ;
- filtrage des options compatibles ;
- tests du flux dirty state.

Il n'ajoute pas :

- éditeur avancé de profil ;
- choix couleur/opacity/scale/profile dans un nouvel écran ;
- Shadow Studio ;
- preview canvas dédiée ;
- migration destructive ;
- runtime.

## 15. Tests ajoutés

Core :

- `packages/map_core/test/shadow/default_shadow_profiles_test.dart`
  - ids stables et uniques ;
  - defaults valides ;
  - `groundStatic` uniquement ;
  - aucun `actorContact` ;
  - aucun `none` ;
  - compatibilité catalogue ;
  - ensure defaults sur catalogue vide ;
  - conservation de profils custom incompatibles ;
  - non-duplication des ids defaults ;
  - opération manifest qui ne change que `shadowCatalog`.

Editor read model :

- filtrage `actorContact` ;
- filtrage `none` ;
- options compatibles seulement.

Editor UI :

- empty catalog affiche message + bouton ;
- actorContact-only affiche message + bouton ;
- none-only affiche message + bouton ;
- clic bouton appelle le callback ;
- après seed, les defaults apparaissent dans le dropdown.

Notifier :

- seed ajoute les defaults et marque dirty ;
- seed ne duplique pas à plusieurs appels ;
- seed ne modifie pas `ProjectElementEntry.shadow`.

## 16. Commandes lancées

Commandes de contexte :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

Format :

```bash
dart format packages/map_core/lib/src/operations/default_shadow_profiles.dart packages/map_core/lib/map_core.dart packages/map_core/test/shadow/default_shadow_profiles_test.dart packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
```

Tests et analyses :

```bash
cd packages/map_core && dart test test/shadow/default_shadow_profiles_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_core && dart test
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette lib/src/features/editor/state test/application/shadow test/features/tileset_library test/editor_notifier_project_dirty_state_test.dart
cd packages/map_editor && flutter test
```

Scans :

```bash
rg -n "ShadowLayerComponent|Flame|Canvas|drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|zOrder|zIndex" packages/map_core packages/map_editor
rg -n "actorContact" packages/map_core/lib/src/operations packages/map_editor/lib/src/application/shadow packages/map_editor/lib/src/ui/panels/tileset_palette
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff -U0 -- packages/map_core packages/map_editor | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 17. Résultats complets des tests ciblés

### Core — default profiles

Commande :

```bash
cd packages/map_core && dart test test/shadow/default_shadow_profiles_test.dart
```

Résultat final :

```text
00:00 +9: All tests passed!
```

### Core — test/shadow

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Résultat final :

```text
00:00 +161: All tests passed!
```

### Editor — application/shadow

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Sortie utile :

```text
00:00 +5: ... element_shadow_read_model_test.dart: buildShadowProfileOptions returns an empty list for an empty catalog
00:00 +6: ... element_shadow_read_model_test.dart: buildShadowProfileOptions preserves catalog order
00:00 +7: ... element_shadow_read_model_test.dart: buildShadowProfileOptions exposes compatible groundStatic profile metadata for a dropdown
00:00 +8: ... element_shadow_read_model_test.dart: buildShadowProfileOptions filters out actorContact and none-mode profiles
00:00 +28: All tests passed!
```

### Editor — features/tileset_library

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library
```

Sortie utile :

```text
00:01 +5: ... element_shadow_section_test.dart: ElementShadowSection shows seed action when the catalog has no compatible profiles
00:01 +6: ... element_shadow_section_test.dart: ElementShadowSection actorContact-only catalog is treated as no compatible profile
00:01 +7: ... element_shadow_section_test.dart: ElementShadowSection none-only catalog is treated as no compatible profile
00:01 +8: ... element_shadow_section_test.dart: ElementShadowSection after seed the default profiles appear in the dropdown
00:01 +18: All tests passed!
```

### Editor — notifier dirty state

Commande :

```bash
cd packages/map_editor && flutter test test/editor_notifier_project_dirty_state_test.dart
```

Sortie utile :

```text
00:00 +6: EditorNotifier project dirty state ensureDefaultShadowProfiles ajoute les defaults et marque dirty
00:00 +7: EditorNotifier project dirty state ensureDefaultShadowProfiles ne duplique pas à plusieurs appels
00:00 +8: All tests passed!
```

## 18. Ligne finale exacte des tests globaux ciblés

`map_core` complet :

```bash
cd packages/map_core && dart test
```

Ligne finale :

```text
00:02 +1517: All tests passed!
```

Analyse `map_core` complète :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Analyse `map_core` ciblée :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Sortie :

```text
Analyzing lib, shadow...
No issues found!
```

Analyse `map_editor` ciblée :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/panels/tileset_palette lib/src/features/editor/state test/application/shadow test/features/tileset_library test/editor_notifier_project_dirty_state_test.dart
```

Sortie :

```text
Analyzing 6 items...
No issues found! (ran in 2.8s)
```

Test complet `map_editor` :

```bash
cd packages/map_editor && flutter test
```

Résultat final exact :

```text
01:30 +1420 -45: Some tests failed.
```

Échecs utiles hors lot observés :

```text
test/pokemon_catalogs_workspace_ui_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/ui_panels_smoke_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/pokemon_catalogs_project_explorer_entry_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/project_scenario_use_cases_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/pokemon_moves_catalog_workspace_ui_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/provider_wiring_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/pokedex_learnset_moves_assist_ui_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/pokedex_workspace_ui_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/step_studio_workspace_regression_test.dart: ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog()) utilisé dans une const expression.
test/update_pokedex_species_learnset_use_case_test.dart: Pokemon learnset references moves absent from the local moves catalog: protect.
```

Ces fichiers ne sont pas modifiés par Shadow-22. Les tests ciblés Shadow-22 et les analyses ciblées passent.

## 19. Résultats des scans anti-dérive

`find .. -name AGENTS.md -print` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Scan large renderer/blur/z :

```bash
rg -n "ShadowLayerComponent|Flame|Canvas|drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|zOrder|zIndex" packages/map_core packages/map_editor
```

Résultat : occurrences existantes dans rapports, tests de rendu éditeur et peintres éditeur. Aucune occurrence ajoutée par Shadow-22 selon le scan diff-only ci-dessous.

Scan ciblé `actorContact` dans les zones Shadow-22 :

```bash
rg -n "actorContact" packages/map_core/lib/src/operations packages/map_editor/lib/src/application/shadow packages/map_editor/lib/src/ui/panels/tileset_palette
```

Résultat :

```text
aucune sortie
```

Diff-only runtime/gameplay/battle :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat :

```text
aucune sortie
```

Diff-only renderer/blur/z :

```bash
git diff -U0 -- packages/map_core packages/map_editor | rg -n "drawImageRect|drawAtlas|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile"
```

Résultat :

```text
aucune sortie
```

`git diff --check` :

```text
aucune sortie
```

## 20. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale Shadow-22 :

```text
aucune sortie
```

État branche constaté :

```text
## main...origin/main [ahead 1]
```

Le `ahead 1` est antérieur au travail Shadow-22.

## 21. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie attendue après création de ce rapport :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
 M packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
 M packages/map_editor/test/application/shadow/element_shadow_read_model_test.dart
 M packages/map_editor/test/editor_notifier_project_dirty_state_test.dart
 M packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
?? packages/map_core/lib/src/operations/default_shadow_profiles.dart
?? packages/map_core/test/shadow/default_shadow_profiles_test.dart
?? reports/shadows/shadow_lot_22_shadow_profile_catalog_editor_availability.md
```

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant ajout de ce rapport :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../shadow/element_shadow_read_model.dart          |  20 +--
 .../src/features/editor/state/editor_notifier.dart |  14 +++
 .../widgets/shadow/element_shadow_section.dart     |  26 +++-
 .../lib/src/ui/panels/tileset_palette_panel.dart   |  10 +-
 .../shadow/element_shadow_read_model_test.dart     |  28 +++--
 .../editor_notifier_project_dirty_state_test.dart  |  62 ++++++++++
 .../element_shadow_section_test.dart               | 135 ++++++++++++++++++++-
 8 files changed, 270 insertions(+), 26 deletions(-)
```

Les deux nouveaux fichiers core et ce rapport sont non suivis, donc absents de cette sortie `git diff --stat`.

## 23. Non-objectifs respectés

- Aucun fichier `map_runtime` modifié.
- Aucun fichier `map_gameplay` modifié.
- Aucun fichier `map_battle` modifié.
- Aucun Shadow Studio complet.
- Aucun profil `actorContact` ajouté comme default d'élément.
- Aucun profil `none` proposé comme profil compatible.
- Aucune mutation de `ProjectElementEntry.shadow` lors du seed.
- Aucun élément existant modifié lors du seed.
- Aucune migration JSON destructive.
- Aucun renderer.
- Aucun Flame Component.
- Aucun `drawImageRect`.
- Aucun `drawAtlas`.
- Aucun `saveLayer`.
- Aucun `ImageFilter`.
- Aucun `runtimeBlur`.
- Aucun `zOrder` / `zIndex`.
- Aucun commit effectué.

## 24. Risques / réserves

- Le seed est explicite et modifie le manifest même si le dialog d'édition d'élément est ensuite fermé sans sauvegarder l'élément. C'est volontaire : le bouton agit sur le catalogue projet, pas sur l'élément.
- Si un projet contient déjà un profil compatible custom, les profils par défaut ne sont pas ajoutés. C'est la règle validée pour éviter d'injecter des defaults inutiles dans un projet déjà configuré.
- Le lot ne fournit pas encore d'éditeur avancé pour changer les profils par défaut. Les valeurs restent des presets V0 hardEdge.
- Le test complet `map_editor` reste rouge sur des dettes hors lot listées en section 18.

## 25. Auto-review finale

- Ai-je rendu des profils Shadow disponibles dans l'éditeur ? oui.
- Ai-je évité de créer des profils actorContact pour ElementShadowSection ? oui.
- Ai-je filtré les profils incompatibles avec les éléments statiques ? oui.
- Ai-je évité de toucher au runtime ? oui.
- Ai-je évité de créer un Shadow Studio complet ? oui.
- Ai-je respecté le flux notifier/use case existant ? oui, via `applyInMemoryProjectManifest(...)`.
- Ai-je évité de modifier ProjectElementEntry.shadow lors du seed des profils ? oui.
- Ai-je évité les doublons de profils par défaut ? oui.
- Ai-je documenté que Shadow-22 résout l'availability editor, pas le rendu runtime ? oui.

## 26. Regard critique sur le prompt

Le prompt est cohérent avec la frontière Shadow-21 / Shadow-22. Le point le plus utile est la distinction entre runtime déjà capable de rendre des ombres configurées et éditeur encore incapable de créer facilement les profils nécessaires.

Point discutable : demander un test complet `map_editor` dans un paquet déjà rouge peut produire beaucoup de bruit. Le résultat reste utile ici parce que les erreurs sont clairement hors fichiers Shadow-22, mais les tests ciblés sont la preuve principale du lot.

## 27. Contenu complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/default_shadow_profiles.dart`

```dart
import '../models/project_manifest.dart';
import '../models/shadow.dart';
import '../models/shadow_catalog.dart';

List<ProjectShadowProfile> createDefaultGroundStaticShadowProfiles() {
  return [
    ProjectShadowProfile(
      id: 'default-ground-soft-ellipse',
      name: 'Ombre douce au sol',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      opacity: 0.35,
    ),
    ProjectShadowProfile(
      id: 'default-ground-wide-ellipse',
      name: 'Ombre large au sol',
      mode: ShadowCasterMode.ellipse,
      renderPass: ShadowRenderPass.groundStatic,
      scaleX: 1.35,
      scaleY: 0.85,
      opacity: 0.28,
    ),
    ProjectShadowProfile(
      id: 'default-ground-contact-blob',
      name: 'Ombre compacte au sol',
      mode: ShadowCasterMode.contactBlob,
      renderPass: ShadowRenderPass.groundStatic,
      opacity: 0.35,
    ),
  ];
}

bool isGroundStaticElementShadowProfile(ProjectShadowProfile profile) {
  return profile.renderPass == ShadowRenderPass.groundStatic &&
      profile.mode != ShadowCasterMode.none;
}

bool hasGroundStaticElementShadowProfiles(ProjectShadowCatalog catalog) {
  return catalog.profiles.any(isGroundStaticElementShadowProfile);
}

ProjectShadowCatalog ensureDefaultGroundStaticShadowProfiles(
  ProjectShadowCatalog catalog,
) {
  if (hasGroundStaticElementShadowProfiles(catalog)) {
    return catalog;
  }
  final existingIds = catalog.profiles.map((profile) => profile.id).toSet();
  final defaultsToAdd = createDefaultGroundStaticShadowProfiles().where(
    (profile) => !existingIds.contains(profile.id),
  );
  return ProjectShadowCatalog(
    profiles: [
      ...catalog.profiles,
      ...defaultsToAdd,
    ],
  );
}

ProjectManifest ensureDefaultGroundStaticShadowProfilesForProject(
  ProjectManifest manifest,
) {
  final nextCatalog = ensureDefaultGroundStaticShadowProfiles(
    manifest.shadowCatalog,
  );
  if (nextCatalog == manifest.shadowCatalog) {
    return manifest;
  }
  return manifest.copyWith(shadowCatalog: nextCatalog);
}
```

### `packages/map_core/test/shadow/default_shadow_profiles_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('default ground static shadow profiles', () {
    test('default profile ids are stable and unique', () {
      final profiles = createDefaultGroundStaticShadowProfiles();

      expect(profiles.map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
      expect(
        profiles.map((profile) => profile.id).toSet(),
        hasLength(profiles.length),
      );
    });

    test('default profiles are valid groundStatic element profiles', () {
      final profiles = createDefaultGroundStaticShadowProfiles();

      expect(profiles, hasLength(3));
      for (final profile in profiles) {
        expect(profile.id.trim(), isNotEmpty);
        expect(profile.name.trim(), isNotEmpty);
        expect(profile.renderPass, ShadowRenderPass.groundStatic);
        expect(profile.renderPass, isNot(ShadowRenderPass.actorContact));
        expect(profile.mode, isNot(ShadowCasterMode.none));
        expect(profile.colorHexRgb, '000000');
        expect(profile.softnessMode, ShadowSoftnessMode.hardEdge);
        expect(isGroundStaticElementShadowProfile(profile), isTrue);
      }
    });

    test('profile compatibility requires groundStatic and non-none mode', () {
      expect(
        isGroundStaticElementShadowProfile(
          _profile('ellipse', mode: ShadowCasterMode.ellipse),
        ),
        isTrue,
      );
      expect(
        isGroundStaticElementShadowProfile(
          _profile(
            'actor',
            mode: ShadowCasterMode.contactBlob,
            renderPass: ShadowRenderPass.actorContact,
          ),
        ),
        isFalse,
      );
      expect(
        isGroundStaticElementShadowProfile(
          _profile('none', mode: ShadowCasterMode.none),
        ),
        isFalse,
      );
    });

    test('catalog compatibility ignores actorContact and none profiles', () {
      expect(
        hasGroundStaticElementShadowProfiles(
            const ProjectShadowCatalog.empty()),
        isFalse,
      );
      expect(
        hasGroundStaticElementShadowProfiles(
          ProjectShadowCatalog(
            profiles: [
              _profile(
                'actor',
                mode: ShadowCasterMode.contactBlob,
                renderPass: ShadowRenderPass.actorContact,
              ),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        hasGroundStaticElementShadowProfiles(
          ProjectShadowCatalog(
            profiles: [_profile('none', mode: ShadowCasterMode.none)],
          ),
        ),
        isFalse,
      );
      expect(
        hasGroundStaticElementShadowProfiles(
          ProjectShadowCatalog(
            profiles: [_profile('ellipse', mode: ShadowCasterMode.ellipse)],
          ),
        ),
        isTrue,
      );
    });

    test('ensure defaults adds defaults to an empty catalog', () {
      final updated = ensureDefaultGroundStaticShadowProfiles(
        const ProjectShadowCatalog.empty(),
      );

      expect(
        updated.profiles.map((profile) => profile.id),
        createDefaultGroundStaticShadowProfiles().map((profile) => profile.id),
      );
    });

    test(
        'ensure defaults preserves incompatible custom profiles before defaults',
        () {
      final actorProfile = _profile(
        'actor-contact',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      );
      final noneProfile = _profile('none-profile', mode: ShadowCasterMode.none);

      final updated = ensureDefaultGroundStaticShadowProfiles(
        ProjectShadowCatalog(profiles: [actorProfile, noneProfile]),
      );

      expect(updated.profiles.take(2), [actorProfile, noneProfile]);
      expect(updated.profiles.skip(2).map((profile) => profile.id), [
        'default-ground-soft-ellipse',
        'default-ground-wide-ellipse',
        'default-ground-contact-blob',
      ]);
    });

    test('ensure defaults does not modify a catalog with a compatible profile',
        () {
      final catalog = ProjectShadowCatalog(
        profiles: [_profile('custom-ground')],
      );

      final updated = ensureDefaultGroundStaticShadowProfiles(catalog);

      expect(updated, catalog);
    });

    test('ensure defaults does not duplicate default ids when seeding', () {
      final existingDefault = createDefaultGroundStaticShadowProfiles().first;
      final actorOnlyDefaultId = ProjectShadowProfile(
        id: existingDefault.id,
        name: 'Actor copy',
        mode: ShadowCasterMode.contactBlob,
        renderPass: ShadowRenderPass.actorContact,
      );

      final updated = ensureDefaultGroundStaticShadowProfiles(
        ProjectShadowCatalog(profiles: [actorOnlyDefaultId]),
      );

      expect(
        updated.profiles.where((profile) => profile.id == existingDefault.id),
        hasLength(1),
      );
      expect(updated.profileById('default-ground-wide-ellipse'), isNotNull);
      expect(updated.profileById('default-ground-contact-blob'), isNotNull);
    });

    test('manifest operation updates only shadowCatalog', () {
      final element = ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'tileset',
        categoryId: 'decor',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 2)),
        ],
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'missing',
        ),
      );
      final manifest = ProjectManifest(
        name: 'Demo',
        maps: const [
          ProjectMapEntry(
              id: 'map', name: 'Map', relativePath: 'maps/map.json'),
        ],
        tilesets: const [],
        elements: [element],
        settings: const ProjectSettings(tileWidth: 24, tileHeight: 24),
        surfaceCatalog: ProjectSurfaceCatalog(),
        shadowCatalog: const ProjectShadowCatalog.empty(),
      );

      final updated = ensureDefaultGroundStaticShadowProfilesForProject(
        manifest,
      );

      expect(updated.shadowCatalog.isNotEmpty, isTrue);
      expect(updated.name, manifest.name);
      expect(updated.maps, manifest.maps);
      expect(updated.tilesets, manifest.tilesets);
      expect(updated.elements, manifest.elements);
      expect(updated.elements.single.shadow, same(element.shadow));
      expect(updated.settings, manifest.settings);
      expect(updated.surfaceCatalog, manifest.surfaceCatalog);
    });
  });
}

ProjectShadowProfile _profile(
  String id, {
  ShadowCasterMode mode = ShadowCasterMode.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
}) {
  return ProjectShadowProfile(
    id: id,
    name: '$id shadow',
    mode: mode,
    renderPass: renderPass,
  );
}
```

### Sections modifiées complètes des fichiers existants

`packages/map_core/lib/map_core.dart` :

```dart
export 'src/operations/default_shadow_profiles.dart';
```

`packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart` :

```dart
List<ShadowProfileOptionReadModel> buildShadowProfileOptions(
  ProjectShadowCatalog catalog,
) {
  return List<ShadowProfileOptionReadModel>.unmodifiable(
    catalog.profiles.where(isGroundStaticElementShadowProfile).map(
          (profile) => ShadowProfileOptionReadModel(
            id: profile.id,
            name: profile.name,
            mode: profile.mode,
            renderPass: profile.renderPass,
            opacity: profile.opacity,
            colorHexRgb: profile.colorHexRgb,
          ),
        ),
  );
}
```

`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` :

```dart
  ProjectManifest? ensureDefaultShadowProfiles() {
    final project = state.project;
    if (project == null) return null;
    final updated = ensureDefaultGroundStaticShadowProfilesForProject(project);
    if (updated == project) {
      return project;
    }
    applyInMemoryProjectManifest(
      updated,
      statusMessage: 'Profils Shadow par défaut ajoutés',
    );
    return updated;
  }
```

`packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart` :

```dart
  const ElementShadowSection({
    super.key,
    required this.manifest,
    required this.element,
    required this.shadow,
    required this.onChanged,
    this.onEnsureDefaultShadowProfiles,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry element;
  final ProjectElementShadowConfig? shadow;
  final ValueChanged<ProjectElementShadowConfig?> onChanged;
  final VoidCallback? onEnsureDefaultShadowProfiles;
```

```dart
          if (profiles.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aucun profil Shadow disponible.',
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoutez les profils par défaut pour commencer à configurer les ombres des éléments.',
              style: TextStyle(color: secondary, fontSize: 10),
            ),
            if (widget.onEnsureDefaultShadowProfiles != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: PushButton(
                  key: const ValueKey(
                    'element-shadow-default-profiles-button',
                  ),
                  controlSize: ControlSize.regular,
                  secondary: true,
                  onPressed: widget.onEnsureDefaultShadowProfiles,
                  child: const Text('Ajouter les profils Shadow par défaut'),
                ),
              ),
            ],
          ],
```

```dart
    final profiles = buildShadowProfileOptionsForManifest(widget.manifest);
    if (profiles.isEmpty) {
      setState(() {
        _activationMessage = 'Aucun profil Shadow disponible.';
      });
      return;
    }

    final currentProfileId = current?.shadowProfileId;
    final selectedProfileId = currentProfileId != null &&
            profiles.any((profile) => profile.id == currentProfileId)
        ? currentProfileId
        : profiles.first.id;
```

`packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart` :

```dart
    ProjectElementShadowConfig? shadowConfig = element.shadow;
    var shadowManifest = project;
```

```dart
                  ElementShadowSection(
                    manifest: shadowManifest,
                    element: element,
                    shadow: shadowConfig,
                    onChanged: (next) {
                      setStateDialog(() {
                        shadowConfig = next;
                      });
                    },
                    onEnsureDefaultShadowProfiles: () {
                      final updated = notifier.ensureDefaultShadowProfiles();
                      if (updated == null) return;
                      setStateDialog(() {
                        shadowManifest = updated;
                      });
                    },
                  ),
```

## 28. Diffs complets ou équivalents /dev/null pour fichiers créés

### Fichiers créés

`/dev/null -> packages/map_core/lib/src/operations/default_shadow_profiles.dart` : contenu complet en section 27.

`/dev/null -> packages/map_core/test/shadow/default_shadow_profiles_test.dart` : contenu complet en section 27.

`/dev/null -> reports/shadows/shadow_lot_22_shadow_profile_catalog_editor_availability.md` : ce fichier constitue le rapport.

### Diff complet des fichiers existants modifiés

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 80f3af11..268dbfd8 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -47,6 +47,7 @@ export 'src/operations/project_path_pattern_preset_json_codec.dart';
 export 'src/operations/project_shadow_catalog_json_codec.dart';
 export 'src/operations/project_shadow_profile_json_codec.dart';
 export 'src/operations/project_json_migrations.dart';
+export 'src/operations/default_shadow_profiles.dart';
 export 'src/operations/tile_visual_frame_timeline.dart';
 export 'src/operations/tile_visual_frame_vertical_atlas.dart';
 export 'src/operations/path_variant_vertical_atlas_mapping.dart';
diff --git a/packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart b/packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
index a42eb4b7..44338161 100644
--- a/packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
+++ b/packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart
@@ -163,16 +163,16 @@ List<ShadowProfileOptionReadModel> buildShadowProfileOptions(
   ProjectShadowCatalog catalog,
 ) {
   return List<ShadowProfileOptionReadModel>.unmodifiable(
-    catalog.profiles.map(
-      (profile) => ShadowProfileOptionReadModel(
-        id: profile.id,
-        name: profile.name,
-        mode: profile.mode,
-        renderPass: profile.renderPass,
-        opacity: profile.opacity,
-        colorHexRgb: profile.colorHexRgb,
-      ),
-    ),
+    catalog.profiles.where(isGroundStaticElementShadowProfile).map(
+          (profile) => ShadowProfileOptionReadModel(
+            id: profile.id,
+            name: profile.name,
+            mode: profile.mode,
+            renderPass: profile.renderPass,
+            opacity: profile.opacity,
+            colorHexRgb: profile.colorHexRgb,
+          ),
+        ),
   );
 }
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index 5d69d1ce..b384cf7a 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -450,6 +450,20 @@ class EditorNotifier extends _$EditorNotifier {
           );
   }
 
+  ProjectManifest? ensureDefaultShadowProfiles() {
+    final project = state.project;
+    if (project == null) return null;
+    final updated = ensureDefaultGroundStaticShadowProfilesForProject(project);
+    if (updated == project) {
+      return project;
+    }
+    applyInMemoryProjectManifest(
+      updated,
+      statusMessage: 'Profils Shadow par défaut ajoutés',
+    );
+    return updated;
+  }
+
   Future<bool> saveProjectManifest() async {
     final fs = _projectWorkspace;
     final project = state.project;
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
index 618fe2d7..20609b7e 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart
@@ -13,12 +13,14 @@ class ElementShadowSection extends StatefulWidget {
     required this.element,
     required this.shadow,
     required this.onChanged,
+    this.onEnsureDefaultShadowProfiles,
   });
 
   final ProjectManifest manifest;
   final ProjectElementEntry element;
   final ProjectElementShadowConfig? shadow;
   final ValueChanged<ProjectElementShadowConfig?> onChanged;
+  final VoidCallback? onEnsureDefaultShadowProfiles;
@@ -132,6 +134,26 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
                 fontWeight: FontWeight.w600,
               ),
             ),
+            const SizedBox(height: 6),
+            Text(
+              'Ajoutez les profils par défaut pour commencer à configurer les ombres des éléments.',
+              style: TextStyle(color: secondary, fontSize: 10),
+            ),
+            if (widget.onEnsureDefaultShadowProfiles != null) ...[
+              const SizedBox(height: 8),
+              Align(
+                alignment: Alignment.centerLeft,
+                child: PushButton(
+                  key: const ValueKey(
+                    'element-shadow-default-profiles-button',
+                  ),
+                  controlSize: ControlSize.regular,
+                  secondary: true,
+                  onPressed: widget.onEnsureDefaultShadowProfiles,
+                  child: const Text('Ajouter les profils Shadow par défaut'),
+                ),
+              ),
+            ],
           ],
@@ -327,7 +349,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
       return;
     }
 
-    final profiles = widget.manifest.shadowCatalog.profiles;
+    final profiles = buildShadowProfileOptionsForManifest(widget.manifest);
     if (profiles.isEmpty) {
       setState(() {
         _activationMessage = 'Aucun profil Shadow disponible.';
@@ -337,7 +359,7 @@ class _ElementShadowSectionState extends State<ElementShadowSection> {
 
     final currentProfileId = current?.shadowProfileId;
     final selectedProfileId = currentProfileId != null &&
-            widget.manifest.shadowCatalog.profileById(currentProfileId) != null
+            profiles.any((profile) => profile.id == currentProfileId)
         ? currentProfileId
         : profiles.first.id;
diff --git a/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart b/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
index d69d5ec5..bd7d629b 100644
--- a/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart
@@ -2566,6 +2566,7 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
     var selectedPresetKind = element.presetKind;
     ElementCollisionProfile? collisionProfile = element.collisionProfile;
     ProjectElementShadowConfig? shadowConfig = element.shadow;
+    var shadowManifest = project;
@@ -2765,7 +2766,7 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
                   ),
                   const SizedBox(height: 8),
                   ElementShadowSection(
-                    manifest: project,
+                    manifest: shadowManifest,
                     element: element,
                     shadow: shadowConfig,
                     onChanged: (next) {
@@ -2773,6 +2774,13 @@ class _TilesetPalettePanelState extends ConsumerState<TilesetPalettePanel> {
                         shadowConfig = next;
                       });
                     },
+                    onEnsureDefaultShadowProfiles: () {
+                      final updated = notifier.ensureDefaultShadowProfiles();
+                      if (updated == null) return;
+                      setStateDialog(() {
+                        shadowManifest = updated;
+                      });
+                    },
                   ),
```

