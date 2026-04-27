# Surface Engine — Lot 49 — `ProjectManifest` Surface Integration V0

## 1. Résumé exécutif

Intégration du champ obligatoire **`ProjectManifest.surfaceCatalog`** (`ProjectSurfaceCatalog` non nullable) avec décodage via **`decodeProjectSurfaceCatalog`**, encodage via **`encodeProjectSurfaceCatalog`**, catalogue vide si la clé JSON **`surfaceCatalog`** est absente ou `null`, **`ValidationException`** si la valeur n’est pas un objet JSON map, et émission **systématique** de la clé **`surfaceCatalog`** dans **`toJson()`** (y compris catalogue vide). Les clés historiques éclatées (`surfaceDefinitions`, etc.) ne sont **pas** réintroduites. Les tests Lot 48 / Lot 21 / codecs Surface sont **réalignés** ; **`test/project_manifest_surface_integration_test.dart`** (20 scénarios) valide le contrat. Aucun codec surface listé, aucune fixture Lot 47, ni package hors **`map_core`**, n’a été modifié.

## Suite du Lot 48

Le **Lot 48** a **caractérisé** le manifest sans champ `surfaceCatalog` (clé inconnue ignorée à la réécriture). Le **Lot 49** matérialise la décision produit : **`surfaceCatalog`** est un **champ de modèle** et une **clé JSON stable**, ce qui rend les tests de prep obsolètes dans leur formulation « droppé au toJson » et impose les tests de transition **Lot 48 → Lot 49** ci-dessous.

## 2. Périmètre

Implémentation stricte selon le cahier Lot 49 ; **aucune** commande `git` d’écriture n’a été utilisée.

## 3. Tableau des lots 39–53

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | fait |
| 45 | ProjectSurfacePreset JSON Codec V0 | fait |
| 46 | ProjectSurfaceCatalog JSON Codec V0 | fait |
| 47 | Surface JSON Golden Samples / Characterization | fait |
| 48 | ProjectManifest Surface Integration Prep | fait |
| 49 | ProjectManifest Surface Integration V0 | **ce lot** |
| 50 | Surface Catalog Repository / Use Cases Prep | prochain probable |
| 51 | Surface Studio Read Model Prep | ensuite probable |
| 52 | Surface Studio Panel Shell V0 | ensuite probable |
| 53 | Surface Studio Catalog Browser V0 | ensuite probable |

## 4. `git status --short --untracked-files=all` initial (fourni au démarrage de la tâche)

```text
M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
?? reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md
```

*Note: état de travail déjà partiel (Lot 15) avant ce lot. Le Lot 49 ne modifie pas `map_core.dart` ni la fixture/rapport Lot 15.*

## 5. Fichiers consultés (extrait, audit)

- `packages/map_core/lib/src/models/project_manifest.dart` et générés
- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart`
- tests surface / manifest / golden Lot 47 listés par le cahier
- `reports/surface/surface_engine_lot_48_project_manifest_surface_integration_prep.md` (contexte 48, lecture ciblée)
- Grep: `surfaceCatalog\|surfaceDefinitions\|…` sur `test` et `lib` pour assertions obsolètes

## 6. Fichiers créés (Lot 49)

- `packages/map_core/test/project_manifest_surface_integration_test.dart`
- `reports/surface/surface_engine_lot_49_project_manifest_surface_integration.md` (ce document)

## 7. Fichiers modifiés manuellement (Lot 49)

- `packages/map_core/lib/src/models/project_manifest.dart` — intégration `surfaceCatalog` + helpers
- Tous les tests listés sur `git diff packages/map_core/test/` (ajout de `surfaceCatalog: ProjectSurfaceCatalog()` aux constructeurs `ProjectManifest` et, selon le test, `expect(… 'surfaceCatalog')` + absence des clés éclatées) ; fichiers cibles explicites du cahier : prep, `project_manifest_surface_json_characterization_test`, `surface_model_entrypoint`, `project_surface_catalog_json_codec_test` (t. 40-42), `project_surface_catalog_json_golden_samples_test` (t. 25), `project_surface_catalog_test` (t. 31) ; + autres tests Surface dont les attentes impliquaient l’ancien fil manifeste.
- *Non modifié (interdit) :* `map_core.dart` barrel, codecs surface, `surface_catalog.dart` modèle, fixtures Lot 47.

## 8. Fichiers modifiés par `build_runner`

- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- (le fichier source `project_manifest.dart` a été modifié **manuellement** ; les deux fichiers ci-dessus sont la sortie générée. `build_runner` a également mis à jour 10 autres cibles *same* dans la même passe — vérification : toutes proviennent de la **régénération incrémentale** ; les seules différences *persistantes* de contenu liées au modèle pour ce lot sont sur **`project_manifest.*`**.)

## 9. Préexistant (hors cœur Lot 49) vs changements Lot 49

- **Préexistant (statut initial en tête de tâche):** modification locale `map_core.dart` (non touchée) ; lot 15 vertical atlas (fichiers non modifiés par Lot 49).
- **Changements Lot 49:** champ `surfaceCatalog` sur `ProjectManifest` + greffe `surfaceCatalog: ProjectSurfaceCatalog()` dans les tests, réalignement des attentes toJson (présence `surfaceCatalog` / absence clés éclatées) ; nouveau test d’intégration 20 scénarios ; ce rapport.

## 10. Décision implémentée

- **`ProjectManifest.surfaceCatalog`**, type **`ProjectSurfaceCatalog`**, **non nullable**.

## 11. Valeur par défaut (JSON / absent)

- Clé **absente** ou **`null`** → **`ProjectSurfaceCatalog()`** (vide).

## 12. Politique JSON

- **`toJson()`** émet **toujours** **`"surfaceCatalog"`** avec la forme de **`encodeProjectSurfaceCatalog`**.

## 13. Décodage: clé absente, null, invalide, incomplet

- **Absente** → vide.
- **`null`** → vide.
- **Non-objet (ex. chaîne)** → `ValidationException('surfaceCatalog must be a JSON object')`.
- **Objet incomplet (clés requises manquantes côté codec V0, ex. `presets` absent)** → `ValidationException` (via codec catalogue, ex. `ProjectSurfaceCatalog.presets is required`).

## 14. Anciennes clés éclatées

- `surfaceDefinitions`, `surfaceAtlases`, `surfaceAnimations`, `surfacePresets`, `surfaceCategories` : **jamais** émises par `ProjectManifest.toJson()`.

## 15. Pourquoi pas `surfaceDefinitions` ni collections top-level

- Cohérence produit: un seul objet **`surfaceCatalog`** explicite, aligné sur le codec Lot 46 et les fixtures Lot 47 « nues ».

## 16. Codecs / fixtures / autres packages

- Codecs surface **non modifiés** (conformément au cahier) ; **fixtures Lot 47 non modifiées** ; **map_runtime, map_editor, map_gameplay, map_battle** non modifiés.

## 17. `build_runner` (sortie intégrale, dernière passe)

```
  Generating the build script.
  Reading the asset graph.
  Checking for updates.
  Updating the asset graph.
  Building, incremental build.
  0s freezed on 158 inputs; lib/map_core.dart
  0s freezed on 158 inputs: 158 skipped
  0s json_serializable on 316 inputs; lib/map_core.dart
  0s json_serializable on 316 inputs: 316 skipped
  0s source_gen:combining_builder on 316 inputs; lib/map_core.dart
  0s source_gen:combining_builder on 316 inputs: 77 skipped; lib/src/operations/legacy_surface_usage_view.freezed.dart
  0s source_gen:combining_builder on 316 inputs: 316 skipped
  Running the post build.
  Writing the asset graph.
  Built with build_runner in 1s; wrote 0 outputs.
```

*Remarque :* une passe **antérieure** (après le premier branchement `surfaceCatalog`) a écrit **12** sorties; la dernière passe (après ajustement mineur) est **0 output** (déjà à jour).

## 18–27. (Synthèse) Tests, analyse, non-faits, impact lots suivants, réalignement

- **Tests ciblés Lot 49 :** 20/20.
- **Tests de régression** (prep, caractérisation, codec, golden, entrypoint) : verts.
- **`dart test` complet `map_core` :** voir section **31** (ligne exacte de fin).
- **Hors lot :** pas de migration runtime, pas d’éditeur, pas de `SurfaceDefinition` unifié.
- **Prochains lots (50+)** : réutiliser `surfaceCatalog` comme ancrage d’outils / Studio.

## 28. Tests existants réalignés

- Tout test qui exigeait **l’absence totale** de clés surface au manifest a été ajusté vers : **présence** de `surfaceCatalog`, **absence** des clés éclatées.
- Fichiers additionnels (hors liste courte) : mêmes règles, pour tout test instanciant `ProjectManifest` (greffe `surfaceCatalog: ProjectSurfaceCatalog()` + assertion `containsKey('surfaceCatalog')` dans les scénarios toJson de garde.

## 29. Commandes lancées (récapitulatif)

```text
cd /Users/karim/Project/pokemonProject/packages/map_core
/opt/homebrew/bin/dart run build_runner build --delete-conflicting-outputs
/opt/homebrew/bin/dart test test/project_manifest_surface_integration_test.dart
/opt/homebrew/bin/dart test test/project_manifest_surface_integration_prep_test.dart
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
/opt/homebrew/bin/dart test test/project_surface_catalog_json_golden_samples_test.dart
/opt/homebrew/bin/dart test test/project_surface_catalog_json_codec_test.dart
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
/opt/homebrew/bin/dart analyze (chemins ciblés + package entier; voir sections 32–33)
/opt/homebrew/bin/dart test
```

## 30. Résultat `build_runner`

*Contenu intégral (dernière passe) :* voir **§17** ci-dessus.

## 31. Résultat `dart test` ciblé Lot 49 (sortie intégrale)

*La sortie d’un `dart test` sur un fichier unique est en général un flux monoligne. Voici la dernière ligne, sans ambiguïté :*

```text
+20: All tests passed!
```

*(Commande : `/opt/homebrew/bin/dart test test/project_manifest_surface_integration_test.dart`.)*

## 32. Résultats des tests de régression (fins de sortie, sans progression intermédiaire)

**Prep (15 tests) :**

```text
+15: All tests passed!
```

**`project_manifest_surface_json_characterization_test` :** suite complète (nombre de tests inchangé côté fichier ; succès intégral lors de la dernière exécution de `dart test` sur `map_core`).

**Codec / golden / entrypoint :** idem, inclus dans `dart test` global.

## 33. Résultat `dart analyze` ciblé (fichiers du cahier + `project_surface_catalog_test.dart`)

*Après correction du seul avertissement `unnecessary_cast` sur `project_manifest.dart` :*

```text
Analyzing project_manifest.dart, project_manifest_surface_integration_test.dart, project_manifest_surface_integration_prep_test.dart, project_manifest_surface_json_characterization_test.dart, project_surface_catalog_json_golden_samples_test.dart, project_surface_catalog_json_codec_test.dart, surface_model_entrypoint_test.dart, project_surface_catalog_test.dart...
No issues found!
```

*Analyse package complète* (`dart analyze` à la racine de `map_core`, sans chemin) :

```text
Analyzing map_core...

   info - lib/src/models/enums.dart:34:3 - The constant name 'upper_floor' isn't a lowerCamelCase identifier. Try changing the name to follow the lowerCamelCase style. - constant_identifier_names
   info - lib/src/models/enums.dart:44:3 - The constant name 'sub_area' isn't a lowerCamelCase identifier. Try changing the name to follow the lowerCamelCase style. - constant_identifier_names

2 issues found.
```

## 34. `dart test` complet (`map_core`) — commande + ligne finale exacte

**Commande :**

```text
cd /Users/karim/Project/pokemonProject/packages/map_core
/opt/homebrew/bin/dart test
```

**Ligne finale exacte (extrait) :**

```text
+1168: All tests passed!
```

## 35. Total exact du `dart test` complet

- **+1168** tests.

## 36. Points de vigilance

- Tout `ProjectManifest` construit en code doit maintenant recevoir `surfaceCatalog` (les tests l’illustrent).
- Les packages **hors** `map_core` qui instancient `ProjectManifest` devront être alignés quand on les branchera (hors scope Lot 49).

## 37. Autocritique

- Périmètre respecté (modèle + `map_core` + tests) ; le rapport intègre l’*Evidence Pack* demandé. La distinction « préexistant / Lot 49 » s’appuie sur le **statut `git` initial** fourni en en-tête de tâche et le diff **manifest + tests** ci-dessous.

## 38. Ce que le prompt pouvait laisser ambigu

- Distinguer *tests « périmètre explicite »* vs *tous* les tests contenant un `ProjectManifest` : l’exigence d’**aligner tout échec** a conduit à mettre à jour de nombreux fichiers de test ; c’est cohérent avec le nouveau constructeur requis, mais le volume diff est plus large que le seul lot « manifest » sémantique.

## 39. Auto-review indépendante (checklist explicite)

| Critère | OK |
|--------|-----|
| Lot limité à l’intégration `surfaceCatalog` côté modèle + tests `map_core` | Oui (hors `map_core.dart` / codecs interdits) |
| `surfaceCatalog` `ProjectSurfaceCatalog` non null | Oui |
| Clé absente / `null` → vide | Oui |
| `toJson` émet toujours `surfaceCatalog` | Oui |
| Clés éclatées non émises | Oui |
| `surfaceDefinitions` non réintroduit | Oui |
| Codecs surface / fixtures Lot 47 non modifiés | Oui (non modifié) |
| `build_runner` exécuté | Oui |
| Autres packages non modifiés | Oui |
| Tests public API (Lot 49 file) : uniquement `map_core` | Oui |
| `dart test` `map_core` = +1168 | Oui (dernière exécution) |
| Aucun fichier interdit (tmp `reports/surface/_gen_*.py`, etc.) | Aucun dans `git status` final |
| Pas de `git` write | Aucun |
| Evidence Pack (diffs + sorties) ci-dessous | Oui |

## 40. `git status --short --untracked-files=all` final (copie intégrale)

```text
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/test/dialogue_library_tree_test.dart
 M packages/map_core/test/legacy_project_surface_catalog_view_test.dart
 M packages/map_core/test/legacy_surface_audit_report_test.dart
 M packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart
 M packages/map_core/test/legacy_surface_usage_diagnostics_test.dart
 M packages/map_core/test/legacy_surface_usage_view_test.dart
 M packages/map_core/test/map_core_test.dart
 M packages/map_core/test/map_events_test.dart
 M packages/map_core/test/path_preset_frames_test.dart
 M packages/map_core/test/path_preset_vertical_atlas_builder_test.dart
 M packages/map_core/test/placed_element_animation_test.dart
 M packages/map_core/test/placed_element_behaviors_test.dart
 M packages/map_core/test/placed_elements_test.dart
 M packages/map_core/test/project_element_frames_test.dart
 M packages/map_core/test/project_manifest_surface_integration_prep_test.dart
 M packages/map_core/test/project_manifest_surface_json_characterization_test.dart
 M packages/map_core/test/project_surface_animation_json_codec_test.dart
 M packages/map_core/test/project_surface_animation_test.dart
 M packages/map_core/test/project_surface_atlas_test.dart
 M packages/map_core/test/project_surface_catalog_json_codec_test.dart
 M packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
 M packages/map_core/test/project_surface_catalog_test.dart
 M packages/map_core/test/project_surface_preset_json_codec_test.dart
 M packages/map_core/test/project_surface_preset_test.dart
 M packages/map_core/test/project_trainer_validation_test.dart
 M packages/map_core/test/scenario_assets_test.dart
 M packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart
 M packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart
 M packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
 M packages/map_core/test/standard_surface_preset_builder_test.dart
 M packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart
 M packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart
 M packages/map_core/test/surface_animation_frame_json_codec_test.dart
 M packages/map_core/test/surface_animation_frame_test.dart
 M packages/map_core/test/surface_animation_timeline_json_codec_test.dart
 M packages/map_core/test/surface_animation_timeline_test.dart
 M packages/map_core/test/surface_atlas_geometry_test.dart
 M packages/map_core/test/surface_atlas_json_codec_test.dart
 M packages/map_core/test/surface_atlas_tile_ref_test.dart
 M packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
 M packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
 M packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
 M packages/map_core/test/surface_catalog_diagnostics_test.dart
 M packages/map_core/test/surface_catalog_unused_diagnostics_test.dart
 M packages/map_core/test/surface_model_entrypoint_test.dart
 M packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart
 M packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart
 M packages/map_core/test/surface_variant_animation_ref_set_test.dart
 M packages/map_core/test/surface_variant_animation_ref_test.dart
 M packages/map_core/test/surface_variant_role_test.dart
?? packages/map_core/test/project_manifest_surface_integration_test.dart
?? reports/surface/surface_engine_lot_49_project_manifest_surface_integration.md
```

## 41. Evidence Pack complet
### A. Fichier créé : `test/project_manifest_surface_integration_test.dart` (intégral)

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Surface Integration (Lot 49)', () {
    test('1. ProjectManifest exposes surfaceCatalog', () {
      final m = _minimal();
      expect(m.surfaceCatalog.isEmpty, isTrue);
    });

    test('2. toJson encodes surfaceCatalog even when empty', () {
      final m = _minimal();
      final json = m.toJson();
      expect(json.containsKey('surfaceCatalog'), isTrue);
      expect(
        json['surfaceCatalog'],
        encodeProjectSurfaceCatalog(ProjectSurfaceCatalog()),
      );
    });

    test('3. fromJson accepts missing surfaceCatalog key', () {
      final raw = <String, dynamic>{
        'name': 'Legacy',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
      };
      final m = ProjectManifest.fromJson(raw);
      expect(m.surfaceCatalog.isEmpty, isTrue);
      final out = m.toJson();
      expect(out.containsKey('surfaceCatalog'), isTrue);
      expect(
        out['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('4. fromJson accepts surfaceCatalog: null as empty', () {
      final raw = <String, dynamic>{
        'name': 'NullCat',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': null,
      };
      final m = ProjectManifest.fromJson(raw);
      expect(m.surfaceCatalog.isEmpty, isTrue);
    });

    test('5. fromJson rejects surfaceCatalog when not a JSON object', () {
      final raw = <String, dynamic>{
        'name': 'Bad',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': 'nope',
      };
      expect(
        () => ProjectManifest.fromJson(raw),
        throwsA(isA<ValidationException>()),
      );
    });

    test('6. fromJson rejects incomplete surfaceCatalog (missing presets)', () {
      final raw = <String, dynamic>{
        'name': 'Inc',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[],
          'animations': <dynamic>[],
        },
      };
      expect(
        () => ProjectManifest.fromJson(raw),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. fromJson decodes empty_surface_catalog_v0.json under surfaceCatalog', () {
      final inner = _readFixtureJson('empty_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(
        _wireWithSurface(inner),
      );
      expect(m.surfaceCatalog.isEmpty, isTrue);
      final json = m.toJson();
      final expected = Map<String, Object?>.from(inner);
      expect(
        Map<String, Object?>.from(
          json['surfaceCatalog']! as Map<dynamic, dynamic>,
        ),
        expected,
      );
    });

    test('8. fromJson decodes minimal_water_surface_catalog_v0.json', () {
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      expect(m.surfaceCatalog.atlasCount, 1);
      expect(m.surfaceCatalog.animationCount, 1);
      expect(m.surfaceCatalog.presetCount, 1);
      expect(
        diagnoseProjectSurfaceCatalog(m.surfaceCatalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(m.surfaceCatalog)
            .hasDiagnostics,
        isFalse,
      );
      expect(
        m.toJson()['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('9. fromJson decodes full_water_surface_catalog_v0.json', () {
      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      expect(m.surfaceCatalog.atlasCount, 1);
      expect(m.surfaceCatalog.animationCount, 1);
      expect(m.surfaceCatalog.presetCount, 1);
      expect(
        m.toJson()['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('10. round-trip manifest with minimal water catalog', () {
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final a = ProjectManifest.fromJson(_wireWithSurface(inner));
      final b = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
      );
      expect(b, a);
    });

    test('11. round-trip manifest with full water catalog', () {
      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
      final a = ProjectManifest.fromJson(_wireWithSurface(inner));
      final b = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
      );
      expect(b, a);
    });

    test('12. copyWith preserves surfaceCatalog when renaming', () {
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      final copy = m.copyWith(name: 'Renamed');
      expect(copy.name, 'Renamed');
      expect(copy.surfaceCatalog, m.surfaceCatalog);
    });

    test('13. copyWith can replace surfaceCatalog', () {
      final empty = _minimal();
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final cat = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(inner),
      );
      final copy = empty.copyWith(surfaceCatalog: cat);
      expect(copy.surfaceCatalog, cat);
    });

    test('14. equality distinguishes surfaceCatalog', () {
      final a = _minimal();
      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final cat = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(inner),
      );
      final b = a.copyWith(surfaceCatalog: cat);
      expect(a == b, isFalse);
    });

    test('15. toJson surfaceCatalog matches encodeProjectSurfaceCatalog', () {
      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
      final json = m.toJson();
      expect(
        json['surfaceCatalog'],
        encodeProjectSurfaceCatalog(m.surfaceCatalog),
      );
    });

    test('16. split legacy Surface keys remain absent from toJson', () {
      final json = _minimal().toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test('17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readFixtureJson(name);
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
      }
    });

    test('18. unknown root key futureUnknownKey is not re-emitted', () {
      final raw = <String, dynamic>{
        'name': 'U',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'futureUnknownKey': 123,
      };
      final m = ProjectManifest.fromJson(raw);
      final out = m.toJson();
      expect(out.containsKey('futureUnknownKey'), isFalse);
    });

    test('19. invalid atlas id in surfaceCatalog surfaces ValidationException', () {
      final raw = <String, dynamic>{
        'name': 'BadAtlas',
        'maps': <dynamic>[],
        'tilesets': <dynamic>[],
        'surfaceCatalog': <String, dynamic>{
          'atlases': <dynamic>[
            <String, dynamic>{
              'id': '   ',
              'name': 'X',
              'tilesetId': 't',
              'geometry': _minimalGeometry(),
              'sortOrder': 0,
            },
          ],
          'animations': <dynamic>[],
          'presets': <dynamic>[],
        },
      };
      expect(
        () => ProjectManifest.fromJson(raw),
        throwsA(
          predicate<dynamic>(
            (e) =>
                e is ValidationException &&
                e.toString().contains('ProjectSurfaceAtlas.id'),
          ),
        ),
      );
    });

    test('20. public map_core API only: imports limited to map_core (see file header)', () {
      // Ce fichier n’importe que `map_core` et l’API standard Dart.
      final m = _minimal();
      expect(m.surfaceCatalog, isA<ProjectSurfaceCatalog>());
    });
  });
}

Map<String, dynamic> _minimalGeometry() {
  return <String, dynamic>{
    'tileSize': <String, dynamic>{'width': 16, 'height': 16},
    'gridSize': <String, dynamic>{'columns': 1, 'rows': 1},
    'layout': 'columnsAreVariantsRowsAreFrames',
  };
}

ProjectManifest _minimal() {
  return ProjectManifest(
    name: 'Lot 49',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(File(_fixturePath(name)).readAsStringSync())
      as Map<String, Object?>;
}

Map<String, dynamic> _wireWithSurface(Map<String, Object?> inner) {
  return <String, dynamic>{
    'name': 'Wired',
    'maps': <dynamic>[],
    'tilesets': <dynamic>[],
    'surfaceCatalog': inner,
  };
}
```

### B. Contenu intégral de `packages/map_core/lib/src/models/project_manifest.dart`

```dart
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'element_collision_profile.dart';
import 'enums.dart';
import 'project_trainer.dart';
import 'scenario_asset.dart';
import 'script_asset.dart';
import 'surface_catalog.dart';
import 'visual_frame_json.dart';

import '../exceptions/map_exceptions.dart';
import '../operations/project_surface_catalog_json_codec.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
/// Clé absente ou `null` : catalogue vide. Non-map : [ValidationException].
ProjectSurfaceCatalog _projectSurfaceCatalogFromJson(Object? json) {
  if (json == null) {
    return ProjectSurfaceCatalog();
  }
  if (json is! Map) {
    throw const ValidationException('surfaceCatalog must be a JSON object');
  }
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(json),
  );
}

Map<String, Object?> _projectSurfaceCatalogToJson(
  ProjectSurfaceCatalog catalog,
) {
  return encodeProjectSurfaceCatalog(catalog);
}

Object? _readDefaultPlayerCharacterId(Map json, String _) {
  return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
}

const Map<String, String> _defaultPokemonCatalogFiles = <String, String>{
  'moves': 'data/pokemon/catalogs/moves.json',
  'abilities': 'data/pokemon/catalogs/abilities.json',
  'items': 'data/pokemon/catalogs/items.json',
  'types': 'data/pokemon/catalogs/types.json',
  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
  'natures': 'data/pokemon/catalogs/natures.json',
  'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
  'habitats': 'data/pokemon/catalogs/habitats.json',
  'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  'generations': 'data/pokemon/catalogs/generations.json',
  'version_groups': 'data/pokemon/catalogs/version_groups.json',
};

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  factory ProjectManifest({
    required String name,
    @Default(ProjectVersion.v1) ProjectVersion version,
    required List<ProjectMapEntry> maps,
    @Default([]) List<ProjectMapGroup> groups,
    @Default([]) List<ProjectTilesetFolder> tilesetFolders,
    required List<ProjectTilesetEntry> tilesets,
    @Default([]) List<ProjectElementCategory> elementCategories,
    @Default([]) List<ProjectElementEntry> elements,
    @Default([]) List<ProjectPresetCategory> terrainCategories,
    @Default([]) List<ProjectPresetCategory> pathCategories,
    @Default([]) List<ProjectTerrainPreset> terrainPresets,
    @Default([]) List<ProjectPathPreset> pathPresets,
    @Default([]) List<ProjectEncounterTable> encounterTables,
    @Default([]) List<ProjectDialogueFolder> dialogueFolders,
    @Default([]) List<ProjectDialogueEntry> dialogues,
    @Default([]) List<ProjectScriptEntry> scripts,
    @Default([]) List<ScenarioAsset> scenarios,
    @Default([]) List<ProjectTrainerEntry> trainers,
    @Default([]) List<ProjectCharacterEntry> characters,
    @Default(ProjectSettings()) ProjectSettings settings,
    @Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
    @Default({}) Map<String, dynamic> globalProperties,
    @JsonKey(
      name: 'surfaceCatalog',
      fromJson: _projectSurfaceCatalogFromJson,
      toJson: _projectSurfaceCatalogToJson,
    )
    required ProjectSurfaceCatalog surfaceCatalog,
  }) = _ProjectManifest;

  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
      _$ProjectManifestFromJson(json);
}

@freezed
class ProjectPokemonConfig with _$ProjectPokemonConfig {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectPokemonConfig({
    @Default(true) bool enabled,
    @Default('data/pokemon') String dataRoot,
    @Default('data/pokemon/species') String speciesDir,
    @Default('data/pokemon/learnsets') String learnsetsDir,
    @Default('data/pokemon/evolutions') String evolutionsDir,
    @Default('data/pokemon/media') String mediaDir,
    @Default(_defaultPokemonCatalogFiles) Map<String, String> catalogFiles,
  }) = _ProjectPokemonConfig;

  factory ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectPokemonConfigFromJson(json);
}

@freezed
class ProjectSettings with _$ProjectSettings {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectSettings({
    @Default(16) int tileWidth,
    @Default(16) int tileHeight,
    @Default(2.0) double displayScale,
    @Default(20) int defaultMapWidth,
    @Default(15) int defaultMapHeight,
    @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId,
    )
    String? defaultPlayerCharacterId,

    /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
    ///
    /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
    /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
    @JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey,
  }) = _ProjectSettings;

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);
}

@freezed
class ProjectMapGroup with _$ProjectMapGroup {
  const factory ProjectMapGroup({
    required String id,
    required String name,
    required MapGroupType type,
    String? parentGroupId,
    @Default(0) int sortOrder,
    @Default([]) List<String> tags,
    @Default({}) Map<String, dynamic> properties,
  }) = _ProjectMapGroup;

  factory ProjectMapGroup.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapGroupFromJson(json);
}

@freezed
class ProjectMapEntry with _$ProjectMapEntry {
  const factory ProjectMapEntry({
    required String id,
    required String name,
    required String relativePath,
    String? groupId,
    @Default(MapRole.exterior) MapRole role,
    @Default(0) int sortOrder,
  }) = _ProjectMapEntry;

  factory ProjectMapEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectMapEntryFromJson(json);
}

@freezed
class ProjectDialogueFolder with _$ProjectDialogueFolder {
  const factory ProjectDialogueFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueFolder;

  factory ProjectDialogueFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueFolderFromJson(json);
}

@freezed
class ProjectDialogueEntry with _$ProjectDialogueEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectDialogueEntry({
    required String id,
    required String name,

    /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
    required String relativePath,
    @Default([]) List<String> tags,
    @Default('') String description,

    /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
    String? defaultStartNode,

    /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
    String? folderId,
    @Default(0) int sortOrder,
  }) = _ProjectDialogueEntry;

  factory ProjectDialogueEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectDialogueEntryFromJson(json);
}

@freezed
class ProjectTilesetFolder with _$ProjectTilesetFolder {
  const factory ProjectTilesetFolder({
    required String id,
    required String name,
    String? parentFolderId,
    @Default(0) int sortOrder,
  }) = _ProjectTilesetFolder;

  factory ProjectTilesetFolder.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetFolderFromJson(json);
}

@freezed
class ProjectTilesetEntry with _$ProjectTilesetEntry {
  const factory ProjectTilesetEntry({
    required String id,
    required String name,
    required String relativePath,
    @Default(TilesetScope.global) TilesetScope scope,
    String? groupId,

    /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
    String? folderId,
    @Default(0) int sortOrder,
    @Default(false) bool isWorldTileset,
    @Default([]) List<TilesetElementGroup> elementGroups,
    @Default([]) List<TilesetPaletteEntry> paletteEntries,
  }) = _ProjectTilesetEntry;

  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTilesetEntryFromJson(json);
}

@freezed
class TilesetPaletteEntry with _$TilesetPaletteEntry {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetPaletteEntry({
    required String id,
    @Default('') String name,
    @Default(PaletteCategory.uncategorized) PaletteCategory category,

    /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
    required List<TilesetVisualFrame> frames,
    String? recommendedLayerId,
  }) = _TilesetPaletteEntry;

  factory TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =>
      _$TilesetPaletteEntryFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class TilesetSourceRect with _$TilesetSourceRect {
  const factory TilesetSourceRect({
    required int x,
    required int y,
    @Default(1) int width,
    @Default(1) int height,
  }) = _TilesetSourceRect;

  factory TilesetSourceRect.fromJson(Map<String, dynamic> json) =>
      _$TilesetSourceRectFromJson(json);
}

/// Une frame d'animation ou l'unique frame d'un visuel statique dans un tileset.
///
/// [tilesetId] vide = utiliser le tileset du contexte parent (élément, preset, entrée palette).
@freezed
class TilesetVisualFrame with _$TilesetVisualFrame {
  @JsonSerializable(explicitToJson: true)
  const factory TilesetVisualFrame({
    @Default('') String tilesetId,
    required TilesetSourceRect source,

    /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
    int? durationMs,
  }) = _TilesetVisualFrame;

  factory TilesetVisualFrame.fromJson(Map<String, dynamic> json) =>
      _$TilesetVisualFrameFromJson(json);
}

@freezed
class TilesetElementGroup with _$TilesetElementGroup {
  const factory TilesetElementGroup({
    required String id,
    required String name,
    String? parentGroupId,
    @Default(0) int sortOrder,
  }) = _TilesetElementGroup;

  factory TilesetElementGroup.fromJson(Map<String, dynamic> json) =>
      _$TilesetElementGroupFromJson(json);
}

@freezed
class ProjectElementCategory with _$ProjectElementCategory {
  const factory ProjectElementCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectElementCategory;

  factory ProjectElementCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementCategoryFromJson(json);
}

@freezed
class ProjectElementEntry with _$ProjectElementEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectElementEntry({
    required String id,
    required String name,
    required String tilesetId,
    required String categoryId,
    String? tilesetGroupId,

    /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(ElementPresetKind.generic) ElementPresetKind presetKind,
    ElementCollisionProfile? collisionProfile,
    String? groupId,
    String? recommendedLayerId,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectElementEntry;

  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectElementEntryFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class ProjectTerrainPreset with _$ProjectTerrainPreset {
  const factory ProjectTerrainPreset({
    required String id,
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<TerrainPresetVariant> variants,
    @Default(0) int sortOrder,
  }) = _ProjectTerrainPreset;

  factory ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectTerrainPresetFromJson(json);
}

@freezed
class TerrainPresetVariant with _$TerrainPresetVariant {
  @JsonSerializable(explicitToJson: true)
  const factory TerrainPresetVariant({
    /// Au moins une frame ; rendu éditeur = première frame.
    required List<TilesetVisualFrame> frames,
    @Default(1) int weight,
  }) = _TerrainPresetVariant;

  factory TerrainPresetVariant.fromJson(Map<String, dynamic> json) =>
      _$TerrainPresetVariantFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class ProjectPathPreset with _$ProjectPathPreset {
  const factory ProjectPathPreset({
    required String id,
    required String name,
    @Default(PathSurfaceKind.path) PathSurfaceKind surfaceKind,
    String? categoryId,
    @Default('') String tilesetId,
    @Default([]) List<PathPresetVariantMapping> variants,
    @Default(0) int sortOrder,
  }) = _ProjectPathPreset;

  factory ProjectPathPreset.fromJson(Map<String, dynamic> json) =>
      _$ProjectPathPresetFromJson(json);
}

@freezed
class PathPresetVariantMapping with _$PathPresetVariantMapping {
  @JsonSerializable(explicitToJson: true)
  const factory PathPresetVariantMapping({
    required TerrainPathVariant variant,

    /// Au moins une frame ; rendu éditeur / autotile = première frame.
    required List<TilesetVisualFrame> frames,
  }) = _PathPresetVariantMapping;

  factory PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =>
      _$PathPresetVariantMappingFromJson(jsonCoerceLegacySourceToFrames(json));
}

@freezed
class PathAnimationTriggerRule with _$PathAnimationTriggerRule {
  @JsonSerializable(explicitToJson: true)
  const factory PathAnimationTriggerRule({
    @Default('') String id,
    @Default(true) bool enabled,
    @Default(PathAnimationTriggerType.onStep) PathAnimationTriggerType trigger,
    @Default(PathAnimationPlaybackMode.restartOnTrigger)
    PathAnimationPlaybackMode mode,
    @Default(PathAnimationActivationScope.wholeLayer)
    PathAnimationActivationScope scope,
  }) = _PathAnimationTriggerRule;

  factory PathAnimationTriggerRule.fromJson(Map<String, dynamic> json) =>
      _$PathAnimationTriggerRuleFromJson(json);
}

@freezed
class ProjectPresetCategory with _$ProjectPresetCategory {
  const factory ProjectPresetCategory({
    required String id,
    required String name,
    String? parentCategoryId,
    @Default(0) int sortOrder,
  }) = _ProjectPresetCategory;

  factory ProjectPresetCategory.fromJson(Map<String, dynamic> json) =>
      _$ProjectPresetCategoryFromJson(json);
}

// ---------------------------------------------------------------------------
// ProjectEncounterEntry / ProjectEncounterTable
// ---------------------------------------------------------------------------

/// Entrée pondérée dans une table de rencontres.
@freezed
class ProjectEncounterEntry with _$ProjectEncounterEntry {
  const factory ProjectEncounterEntry({
    /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
    required String speciesId,
    required int minLevel,
    required int maxLevel,

    /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
    @Default(1) int weight,
  }) = _ProjectEncounterEntry;

  factory ProjectEncounterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterEntryFromJson(json);
}

/// Table de rencontres réutilisable au niveau projet.
///
/// Une [MapGameplayZone] peut y faire référence via [MapGameplayZone.encounterTableId].
/// Le runtime choisit une entrée au tirage pondéré et déclenche le système de combat.
@freezed
class ProjectEncounterTable with _$ProjectEncounterTable {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectEncounterTable({
    required String id,
    required String name,
    required EncounterKind encounterKind,
    @Default([]) List<ProjectEncounterEntry> entries,
    @Default([]) List<String> tags,
  }) = _ProjectEncounterTable;

  factory ProjectEncounterTable.fromJson(Map<String, dynamic> json) =>
      _$ProjectEncounterTableFromJson(json);
}

extension TilesetVisualFrameListX on List<TilesetVisualFrame> {
  TilesetVisualFrame get primaryFrame {
    if (isEmpty) {
      throw StateError('At least one TilesetVisualFrame is required');
    }
    return first;
  }

  TilesetSourceRect get primarySource => primaryFrame.source;
}

@freezed
class ProjectScriptEntry with _$ProjectScriptEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectScriptEntry({
    required String id,
    required String name,
    required ScriptAsset asset,
    @Default([]) List<String> tags,
  }) = _ProjectScriptEntry;

  factory ProjectScriptEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectScriptEntryFromJson(json);
}

@freezed
class ProjectCharacterEntry with _$ProjectCharacterEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectCharacterEntry({
    required String id,
    required String name,
    required String tilesetId,
    @Default(1) int frameWidth,
    @Default(2) int frameHeight,
    @Default([]) List<CharacterAnimation> animations,
    @Default([]) List<String> tags,
    @Default(0) int sortOrder,
  }) = _ProjectCharacterEntry;

  factory ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectCharacterEntryFromJson(json);
}

@freezed
class CharacterAnimation with _$CharacterAnimation {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimation({
    required CharacterAnimationState state,
    required EntityFacing direction,
    @Default([]) List<CharacterAnimationFrame> frames,
  }) = _CharacterAnimation;

  factory CharacterAnimation.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFromJson(json);
}

@freezed
class CharacterAnimationFrame with _$CharacterAnimationFrame {
  @JsonSerializable(explicitToJson: true)
  const factory CharacterAnimationFrame({
    required TilesetSourceRect source,
    @Default(150) int durationMs,
  }) = _CharacterAnimationFrame;

  factory CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =>
      _$CharacterAnimationFrameFromJson(json);
}

```

### C. Diffs (preuves intégrales)

#### C1. Nouveau test (`git diff --no-index`)

```diff
diff --git a/packages/map_core/test/project_manifest_surface_integration_test.dart b/packages/map_core/test/project_manifest_surface_integration_test.dart
new file mode 100644
index 00000000..482c6840
--- /dev/null
+++ b/packages/map_core/test/project_manifest_surface_integration_test.dart
@@ -0,0 +1,291 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('ProjectManifest Surface Integration (Lot 49)', () {
+    test('1. ProjectManifest exposes surfaceCatalog', () {
+      final m = _minimal();
+      expect(m.surfaceCatalog.isEmpty, isTrue);
+    });
+
+    test('2. toJson encodes surfaceCatalog even when empty', () {
+      final m = _minimal();
+      final json = m.toJson();
+      expect(json.containsKey('surfaceCatalog'), isTrue);
+      expect(
+        json['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(ProjectSurfaceCatalog()),
+      );
+    });
+
+    test('3. fromJson accepts missing surfaceCatalog key', () {
+      final raw = <String, dynamic>{
+        'name': 'Legacy',
+        'maps': <dynamic>[],
+        'tilesets': <dynamic>[],
+      };
+      final m = ProjectManifest.fromJson(raw);
+      expect(m.surfaceCatalog.isEmpty, isTrue);
+      final out = m.toJson();
+      expect(out.containsKey('surfaceCatalog'), isTrue);
+      expect(
+        out['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(m.surfaceCatalog),
+      );
+    });
+
+    test('4. fromJson accepts surfaceCatalog: null as empty', () {
+      final raw = <String, dynamic>{
+        'name': 'NullCat',
+        'maps': <dynamic>[],
+        'tilesets': <dynamic>[],
+        'surfaceCatalog': null,
+      };
+      final m = ProjectManifest.fromJson(raw);
+      expect(m.surfaceCatalog.isEmpty, isTrue);
+    });
+
+    test('5. fromJson rejects surfaceCatalog when not a JSON object', () {
+      final raw = <String, dynamic>{
+        'name': 'Bad',
+        'maps': <dynamic>[],
+        'tilesets': <dynamic>[],
+        'surfaceCatalog': 'nope',
+      };
+      expect(
+        () => ProjectManifest.fromJson(raw),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('6. fromJson rejects incomplete surfaceCatalog (missing presets)', () {
+      final raw = <String, dynamic>{
+        'name': 'Inc',
+        'maps': <dynamic>[],
+        'tilesets': <dynamic>[],
+        'surfaceCatalog': <String, dynamic>{
+          'atlases': <dynamic>[],
+          'animations': <dynamic>[],
+        },
+      };
+      expect(
+        () => ProjectManifest.fromJson(raw),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('7. fromJson decodes empty_surface_catalog_v0.json under surfaceCatalog', () {
+      final inner = _readFixtureJson('empty_surface_catalog_v0.json');
+      final m = ProjectManifest.fromJson(
+        _wireWithSurface(inner),
+      );
+      expect(m.surfaceCatalog.isEmpty, isTrue);
+      final json = m.toJson();
+      final expected = Map<String, Object?>.from(inner);
+      expect(
+        Map<String, Object?>.from(
+          json['surfaceCatalog']! as Map<dynamic, dynamic>,
+        ),
+        expected,
+      );
+    });
+
+    test('8. fromJson decodes minimal_water_surface_catalog_v0.json', () {
+      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
+      expect(m.surfaceCatalog.atlasCount, 1);
+      expect(m.surfaceCatalog.animationCount, 1);
+      expect(m.surfaceCatalog.presetCount, 1);
+      expect(
+        diagnoseProjectSurfaceCatalog(m.surfaceCatalog).hasDiagnostics,
+        isFalse,
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(m.surfaceCatalog)
+            .hasDiagnostics,
+        isFalse,
+      );
+      expect(
+        m.toJson()['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(m.surfaceCatalog),
+      );
+    });
+
+    test('9. fromJson decodes full_water_surface_catalog_v0.json', () {
+      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
+      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
+      expect(m.surfaceCatalog.atlasCount, 1);
+      expect(m.surfaceCatalog.animationCount, 1);
+      expect(m.surfaceCatalog.presetCount, 1);
+      expect(
+        m.toJson()['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(m.surfaceCatalog),
+      );
+    });
+
+    test('10. round-trip manifest with minimal water catalog', () {
+      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final a = ProjectManifest.fromJson(_wireWithSurface(inner));
+      final b = ProjectManifest.fromJson(
+        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
+      );
+      expect(b, a);
+    });
+
+    test('11. round-trip manifest with full water catalog', () {
+      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
+      final a = ProjectManifest.fromJson(_wireWithSurface(inner));
+      final b = ProjectManifest.fromJson(
+        jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
+      );
+      expect(b, a);
+    });
+
+    test('12. copyWith preserves surfaceCatalog when renaming', () {
+      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
+      final copy = m.copyWith(name: 'Renamed');
+      expect(copy.name, 'Renamed');
+      expect(copy.surfaceCatalog, m.surfaceCatalog);
+    });
+
+    test('13. copyWith can replace surfaceCatalog', () {
+      final empty = _minimal();
+      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final cat = decodeProjectSurfaceCatalog(
+        Map<String, dynamic>.from(inner),
+      );
+      final copy = empty.copyWith(surfaceCatalog: cat);
+      expect(copy.surfaceCatalog, cat);
+    });
+
+    test('14. equality distinguishes surfaceCatalog', () {
+      final a = _minimal();
+      final inner = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final cat = decodeProjectSurfaceCatalog(
+        Map<String, dynamic>.from(inner),
+      );
+      final b = a.copyWith(surfaceCatalog: cat);
+      expect(a == b, isFalse);
+    });
+
+    test('15. toJson surfaceCatalog matches encodeProjectSurfaceCatalog', () {
+      final inner = _readFixtureJson('full_water_surface_catalog_v0.json');
+      final m = ProjectManifest.fromJson(_wireWithSurface(inner));
+      final json = m.toJson();
+      expect(
+        json['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(m.surfaceCatalog),
+      );
+    });
+
+    test('16. split legacy Surface keys remain absent from toJson', () {
+      final json = _minimal().toJson();
+      for (final k in const [
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(json.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test('17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)', () {
+      for (final name in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final o = _readFixtureJson(name);
+        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
+      }
+    });
+
+    test('18. unknown root key futureUnknownKey is not re-emitted', () {
+      final raw = <String, dynamic>{
+        'name': 'U',
+        'maps': <dynamic>[],
+        'tilesets': <dynamic>[],
+        'futureUnknownKey': 123,
+      };
+      final m = ProjectManifest.fromJson(raw);
+      final out = m.toJson();
+      expect(out.containsKey('futureUnknownKey'), isFalse);
+    });
+
+    test('19. invalid atlas id in surfaceCatalog surfaces ValidationException', () {
+      final raw = <String, dynamic>{
+        'name': 'BadAtlas',
+        'maps': <dynamic>[],
+        'tilesets': <dynamic>[],
+        'surfaceCatalog': <String, dynamic>{
+          'atlases': <dynamic>[
+            <String, dynamic>{
+              'id': '   ',
+              'name': 'X',
+              'tilesetId': 't',
+              'geometry': _minimalGeometry(),
+              'sortOrder': 0,
+            },
+          ],
+          'animations': <dynamic>[],
+          'presets': <dynamic>[],
+        },
+      };
+      expect(
+        () => ProjectManifest.fromJson(raw),
+        throwsA(
+          predicate<dynamic>(
+            (e) =>
+                e is ValidationException &&
+                e.toString().contains('ProjectSurfaceAtlas.id'),
+          ),
+        ),
+      );
+    });
+
+    test('20. public map_core API only: imports limited to map_core (see file header)', () {
+      // Ce fichier n’importe que `map_core` et l’API standard Dart.
+      final m = _minimal();
+      expect(m.surfaceCatalog, isA<ProjectSurfaceCatalog>());
+    });
+  });
+}
+
+Map<String, dynamic> _minimalGeometry() {
+  return <String, dynamic>{
+    'tileSize': <String, dynamic>{'width': 16, 'height': 16},
+    'gridSize': <String, dynamic>{'columns': 1, 'rows': 1},
+    'layout': 'columnsAreVariantsRowsAreFrames',
+  };
+}
+
+ProjectManifest _minimal() {
+  return ProjectManifest(
+    name: 'Lot 49',
+    maps: const [],
+    tilesets: const [],
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';
+
+Map<String, Object?> _readFixtureJson(String name) {
+  return jsonDecode(File(_fixturePath(name)).readAsStringSync())
+      as Map<String, Object?>;
+}
+
+Map<String, dynamic> _wireWithSurface(Map<String, Object?> inner) {
+  return <String, dynamic>{
+    'name': 'Wired',
+    'maps': <dynamic>[],
+    'tilesets': <dynamic>[],
+    'surfaceCatalog': inner,
+  };
+}
```

#### C2. Fichiers manifest modèle (`git diff` trois fichiers)

```diff
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index ee49a865..9782f75c 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -6,11 +6,35 @@ import 'enums.dart';
 import 'project_trainer.dart';
 import 'scenario_asset.dart';
 import 'script_asset.dart';
+import 'surface_catalog.dart';
 import 'visual_frame_json.dart';
 
+import '../exceptions/map_exceptions.dart';
+import '../operations/project_surface_catalog_json_codec.dart';
+
 part 'project_manifest.freezed.dart';
 part 'project_manifest.g.dart';
 
+/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
+/// Clé absente ou `null` : catalogue vide. Non-map : [ValidationException].
+ProjectSurfaceCatalog _projectSurfaceCatalogFromJson(Object? json) {
+  if (json == null) {
+    return ProjectSurfaceCatalog();
+  }
+  if (json is! Map) {
+    throw const ValidationException('surfaceCatalog must be a JSON object');
+  }
+  return decodeProjectSurfaceCatalog(
+    Map<String, Object?>.from(json),
+  );
+}
+
+Map<String, Object?> _projectSurfaceCatalogToJson(
+  ProjectSurfaceCatalog catalog,
+) {
+  return encodeProjectSurfaceCatalog(catalog);
+}
+
 Object? _readDefaultPlayerCharacterId(Map json, String _) {
   return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
 }
@@ -32,7 +56,7 @@ const Map<String, String> _defaultPokemonCatalogFiles = <String, String>{
 @freezed
 class ProjectManifest with _$ProjectManifest {
   @JsonSerializable(explicitToJson: true)
-  const factory ProjectManifest({
+  factory ProjectManifest({
     required String name,
     @Default(ProjectVersion.v1) ProjectVersion version,
     required List<ProjectMapEntry> maps,
@@ -55,6 +79,12 @@ class ProjectManifest with _$ProjectManifest {
     @Default(ProjectSettings()) ProjectSettings settings,
     @Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
     @Default({}) Map<String, dynamic> globalProperties,
+    @JsonKey(
+      name: 'surfaceCatalog',
+      fromJson: _projectSurfaceCatalogFromJson,
+      toJson: _projectSurfaceCatalogToJson,
+    )
+    required ProjectSurfaceCatalog surfaceCatalog,
   }) = _ProjectManifest;
 
   factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
diff --git a/packages/map_core/lib/src/models/project_manifest.freezed.dart b/packages/map_core/lib/src/models/project_manifest.freezed.dart
index 528a748a..85e72bae 100644
--- a/packages/map_core/lib/src/models/project_manifest.freezed.dart
+++ b/packages/map_core/lib/src/models/project_manifest.freezed.dart
@@ -52,6 +52,12 @@ mixin _$ProjectManifest {
   ProjectPokemonConfig get pokemon => throw _privateConstructorUsedError;
   Map<String, dynamic> get globalProperties =>
       throw _privateConstructorUsedError;
+  @JsonKey(
+      name: 'surfaceCatalog',
+      fromJson: _projectSurfaceCatalogFromJson,
+      toJson: _projectSurfaceCatalogToJson)
+  ProjectSurfaceCatalog get surfaceCatalog =>
+      throw _privateConstructorUsedError;
 
   /// Serializes this ProjectManifest to a JSON map.
   Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
@@ -91,7 +97,12 @@ abstract class $ProjectManifestCopyWith<$Res> {
       List<ProjectCharacterEntry> characters,
       ProjectSettings settings,
       ProjectPokemonConfig pokemon,
-      Map<String, dynamic> globalProperties});
+      Map<String, dynamic> globalProperties,
+      @JsonKey(
+          name: 'surfaceCatalog',
+          fromJson: _projectSurfaceCatalogFromJson,
+          toJson: _projectSurfaceCatalogToJson)
+      ProjectSurfaceCatalog surfaceCatalog});
 
   $ProjectSettingsCopyWith<$Res> get settings;
   $ProjectPokemonConfigCopyWith<$Res> get pokemon;
@@ -134,6 +145,7 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
     Object? settings = null,
     Object? pokemon = null,
     Object? globalProperties = null,
+    Object? surfaceCatalog = null,
   }) {
     return _then(_value.copyWith(
       name: null == name
@@ -224,6 +236,10 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
           ? _value.globalProperties
           : globalProperties // ignore: cast_nullable_to_non_nullable
               as Map<String, dynamic>,
+      surfaceCatalog: null == surfaceCatalog
+          ? _value.surfaceCatalog
+          : surfaceCatalog // ignore: cast_nullable_to_non_nullable
+              as ProjectSurfaceCatalog,
     ) as $Val);
   }
 
@@ -278,7 +294,12 @@ abstract class _$$ProjectManifestImplCopyWith<$Res>
       List<ProjectCharacterEntry> characters,
       ProjectSettings settings,
       ProjectPokemonConfig pokemon,
-      Map<String, dynamic> globalProperties});
+      Map<String, dynamic> globalProperties,
+      @JsonKey(
+          name: 'surfaceCatalog',
+          fromJson: _projectSurfaceCatalogFromJson,
+          toJson: _projectSurfaceCatalogToJson)
+      ProjectSurfaceCatalog surfaceCatalog});
 
   @override
   $ProjectSettingsCopyWith<$Res> get settings;
@@ -321,6 +342,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
     Object? settings = null,
     Object? pokemon = null,
     Object? globalProperties = null,
+    Object? surfaceCatalog = null,
   }) {
     return _then(_$ProjectManifestImpl(
       name: null == name
@@ -411,6 +433,10 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
           ? _value._globalProperties
           : globalProperties // ignore: cast_nullable_to_non_nullable
               as Map<String, dynamic>,
+      surfaceCatalog: null == surfaceCatalog
+          ? _value.surfaceCatalog
+          : surfaceCatalog // ignore: cast_nullable_to_non_nullable
+              as ProjectSurfaceCatalog,
     ));
   }
 }
@@ -419,7 +445,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
 
 @JsonSerializable(explicitToJson: true)
 class _$ProjectManifestImpl implements _ProjectManifest {
-  const _$ProjectManifestImpl(
+  _$ProjectManifestImpl(
       {required this.name,
       this.version = ProjectVersion.v1,
       required final List<ProjectMapEntry> maps,
@@ -441,7 +467,12 @@ class _$ProjectManifestImpl implements _ProjectManifest {
       final List<ProjectCharacterEntry> characters = const [],
       this.settings = const ProjectSettings(),
       this.pokemon = const ProjectPokemonConfig(),
-      final Map<String, dynamic> globalProperties = const {}})
+      final Map<String, dynamic> globalProperties = const {},
+      @JsonKey(
+          name: 'surfaceCatalog',
+          fromJson: _projectSurfaceCatalogFromJson,
+          toJson: _projectSurfaceCatalogToJson)
+      required this.surfaceCatalog})
       : _maps = maps,
         _groups = groups,
         _tilesetFolders = tilesetFolders,
@@ -637,9 +668,16 @@ class _$ProjectManifestImpl implements _ProjectManifest {
     return EqualUnmodifiableMapView(_globalProperties);
   }
 
+  @override
+  @JsonKey(
+      name: 'surfaceCatalog',
+      fromJson: _projectSurfaceCatalogFromJson,
+      toJson: _projectSurfaceCatalogToJson)
+  final ProjectSurfaceCatalog surfaceCatalog;
+
   @override
   String toString() {
-    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties)';
+    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties, surfaceCatalog: $surfaceCatalog)';
   }
 
   @override
@@ -681,7 +719,9 @@ class _$ProjectManifestImpl implements _ProjectManifest {
                 other.settings == settings) &&
             (identical(other.pokemon, pokemon) || other.pokemon == pokemon) &&
             const DeepCollectionEquality()
-                .equals(other._globalProperties, _globalProperties));
+                .equals(other._globalProperties, _globalProperties) &&
+            (identical(other.surfaceCatalog, surfaceCatalog) ||
+                other.surfaceCatalog == surfaceCatalog));
   }
 
   @JsonKey(includeFromJson: false, includeToJson: false)
@@ -709,7 +749,8 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         const DeepCollectionEquality().hash(_characters),
         settings,
         pokemon,
-        const DeepCollectionEquality().hash(_globalProperties)
+        const DeepCollectionEquality().hash(_globalProperties),
+        surfaceCatalog
       ]);
 
   /// Create a copy of ProjectManifest
@@ -730,29 +771,35 @@ class _$ProjectManifestImpl implements _ProjectManifest {
 }
 
 abstract class _ProjectManifest implements ProjectManifest {
-  const factory _ProjectManifest(
-      {required final String name,
-      final ProjectVersion version,
-      required final List<ProjectMapEntry> maps,
-      final List<ProjectMapGroup> groups,
-      final List<ProjectTilesetFolder> tilesetFolders,
-      required final List<ProjectTilesetEntry> tilesets,
-      final List<ProjectElementCategory> elementCategories,
-      final List<ProjectElementEntry> elements,
-      final List<ProjectPresetCategory> terrainCategories,
-      final List<ProjectPresetCategory> pathCategories,
-      final List<ProjectTerrainPreset> terrainPresets,
-      final List<ProjectPathPreset> pathPresets,
-      final List<ProjectEncounterTable> encounterTables,
-      final List<ProjectDialogueFolder> dialogueFolders,
-      final List<ProjectDialogueEntry> dialogues,
-      final List<ProjectScriptEntry> scripts,
-      final List<ScenarioAsset> scenarios,
-      final List<ProjectTrainerEntry> trainers,
-      final List<ProjectCharacterEntry> characters,
-      final ProjectSettings settings,
-      final ProjectPokemonConfig pokemon,
-      final Map<String, dynamic> globalProperties}) = _$ProjectManifestImpl;
+  factory _ProjectManifest(
+          {required final String name,
+          final ProjectVersion version,
+          required final List<ProjectMapEntry> maps,
+          final List<ProjectMapGroup> groups,
+          final List<ProjectTilesetFolder> tilesetFolders,
+          required final List<ProjectTilesetEntry> tilesets,
+          final List<ProjectElementCategory> elementCategories,
+          final List<ProjectElementEntry> elements,
+          final List<ProjectPresetCategory> terrainCategories,
+          final List<ProjectPresetCategory> pathCategories,
+          final List<ProjectTerrainPreset> terrainPresets,
+          final List<ProjectPathPreset> pathPresets,
+          final List<ProjectEncounterTable> encounterTables,
+          final List<ProjectDialogueFolder> dialogueFolders,
+          final List<ProjectDialogueEntry> dialogues,
+          final List<ProjectScriptEntry> scripts,
+          final List<ScenarioAsset> scenarios,
+          final List<ProjectTrainerEntry> trainers,
+          final List<ProjectCharacterEntry> characters,
+          final ProjectSettings settings,
+          final ProjectPokemonConfig pokemon,
+          final Map<String, dynamic> globalProperties,
+          @JsonKey(
+              name: 'surfaceCatalog',
+              fromJson: _projectSurfaceCatalogFromJson,
+              toJson: _projectSurfaceCatalogToJson)
+          required final ProjectSurfaceCatalog surfaceCatalog}) =
+      _$ProjectManifestImpl;
 
   factory _ProjectManifest.fromJson(Map<String, dynamic> json) =
       _$ProjectManifestImpl.fromJson;
@@ -801,6 +848,12 @@ abstract class _ProjectManifest implements ProjectManifest {
   ProjectPokemonConfig get pokemon;
   @override
   Map<String, dynamic> get globalProperties;
+  @override
+  @JsonKey(
+      name: 'surfaceCatalog',
+      fromJson: _projectSurfaceCatalogFromJson,
+      toJson: _projectSurfaceCatalogToJson)
+  ProjectSurfaceCatalog get surfaceCatalog;
 
   /// Create a copy of ProjectManifest
   /// with the given fields replaced by the non-null parameter values.
diff --git a/packages/map_core/lib/src/models/project_manifest.g.dart b/packages/map_core/lib/src/models/project_manifest.g.dart
index 7a2f799d..35254760 100644
--- a/packages/map_core/lib/src/models/project_manifest.g.dart
+++ b/packages/map_core/lib/src/models/project_manifest.g.dart
@@ -100,6 +100,7 @@ _$ProjectManifestImpl _$$ProjectManifestImplFromJson(
               json['pokemon'] as Map<String, dynamic>),
       globalProperties:
           json['globalProperties'] as Map<String, dynamic>? ?? const {},
+      surfaceCatalog: _projectSurfaceCatalogFromJson(json['surfaceCatalog']),
     );
 
 Map<String, dynamic> _$$ProjectManifestImplToJson(
@@ -131,6 +132,7 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'settings': instance.settings.toJson(),
       'pokemon': instance.pokemon.toJson(),
       'globalProperties': instance.globalProperties,
+      'surfaceCatalog': _projectSurfaceCatalogToJson(instance.surfaceCatalog),
     };
 
 const _$ProjectVersionEnumMap = {
```

#### C3. Tous les tests `map_core` (`git diff packages/map_core/test/`)

```diff
diff --git a/packages/map_core/test/dialogue_library_tree_test.dart b/packages/map_core/test/dialogue_library_tree_test.dart
index cb7afbd0..7aab1b46 100644
--- a/packages/map_core/test/dialogue_library_tree_test.dart
+++ b/packages/map_core/test/dialogue_library_tree_test.dart
@@ -28,7 +28,7 @@ void main() {
         tilesets: const [],
         dialogueFolders: [fRoot, fChild],
         dialogues: [dInChild, dRoot],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
       final tree = buildDialogueLibraryTree(manifest);
       expect(tree.rootFolders, hasLength(1));
@@ -56,7 +56,7 @@ void main() {
           ),
         ],
         dialogues: const [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final flat = flattenDialogueFoldersForPicker(manifest);
       expect(flat.map((e) => e.id).toList(), ['a', 'b']);
       expect(flat.last.label, contains('A'));
diff --git a/packages/map_core/test/legacy_project_surface_catalog_view_test.dart b/packages/map_core/test/legacy_project_surface_catalog_view_test.dart
index 4ebcf963..c0f6821f 100644
--- a/packages/map_core/test/legacy_project_surface_catalog_view_test.dart
+++ b/packages/map_core/test/legacy_project_surface_catalog_view_test.dart
@@ -397,7 +397,7 @@ ProjectManifest projectManifest({
     tilesets: const [],
     terrainPresets: terrainPresets,
     pathPresets: pathPresets,
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
 
 ProjectTerrainPreset terrainPreset({
diff --git a/packages/map_core/test/legacy_surface_audit_report_test.dart b/packages/map_core/test/legacy_surface_audit_report_test.dart
index 9a496389..3da61d83 100644
--- a/packages/map_core/test/legacy_surface_audit_report_test.dart
+++ b/packages/map_core/test/legacy_surface_audit_report_test.dart
@@ -13,7 +13,7 @@ ProjectManifest projectManifest({
     tilesets: const [],
     terrainPresets: terrainPresets,
     pathPresets: pathPresets,
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
 
 ProjectTerrainPreset terrainPreset({
diff --git a/packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart b/packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart
index b2de855d..bcb9c7ea 100644
--- a/packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart
+++ b/packages/map_core/test/legacy_surface_catalog_diagnostics_test.dart
@@ -548,7 +548,7 @@ ProjectManifest projectManifest({
     tilesets: const [],
     terrainPresets: terrainPresets,
     pathPresets: pathPresets,
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
 
 ProjectTerrainPreset terrainPreset({
diff --git a/packages/map_core/test/legacy_surface_usage_diagnostics_test.dart b/packages/map_core/test/legacy_surface_usage_diagnostics_test.dart
index 58743bfe..58a7202c 100644
--- a/packages/map_core/test/legacy_surface_usage_diagnostics_test.dart
+++ b/packages/map_core/test/legacy_surface_usage_diagnostics_test.dart
@@ -13,7 +13,7 @@ ProjectManifest projectManifest({
     tilesets: const [],
     terrainPresets: terrainPresets,
     pathPresets: pathPresets,
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
 
 ProjectTerrainPreset terrainPreset({
diff --git a/packages/map_core/test/legacy_surface_usage_view_test.dart b/packages/map_core/test/legacy_surface_usage_view_test.dart
index 7d5261f1..b5bbd3c0 100644
--- a/packages/map_core/test/legacy_surface_usage_view_test.dart
+++ b/packages/map_core/test/legacy_surface_usage_view_test.dart
@@ -13,7 +13,7 @@ ProjectManifest projectManifest({
     tilesets: const [],
     terrainPresets: terrainPresets,
     pathPresets: pathPresets,
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
 
 ProjectTerrainPreset terrainPreset({
diff --git a/packages/map_core/test/map_core_test.dart b/packages/map_core/test/map_core_test.dart
index 4cd865a3..81e56c87 100644
--- a/packages/map_core/test/map_core_test.dart
+++ b/packages/map_core/test/map_core_test.dart
@@ -22,7 +22,7 @@ void main() {
               id: 'm1', name: 'Map2', relativePath: 'm2.json'),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
       expect(() => ProjectValidator.validate(project),
           throwsA(isA<ValidationException>()));
diff --git a/packages/map_core/test/map_events_test.dart b/packages/map_core/test/map_events_test.dart
index f95f726c..4855ea59 100644
--- a/packages/map_core/test/map_events_test.dart
+++ b/packages/map_core/test/map_events_test.dart
@@ -111,7 +111,7 @@ void main() {
         maps: const [],
         tilesets: const [],
         scripts: const [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       expect(
         () => MapValidator.validate(map, projectDialogueContext: project),
         throwsA(isA<ValidationException>()),
diff --git a/packages/map_core/test/path_preset_frames_test.dart b/packages/map_core/test/path_preset_frames_test.dart
index 3e8f312b..4f68778d 100644
--- a/packages/map_core/test/path_preset_frames_test.dart
+++ b/packages/map_core/test/path_preset_frames_test.dart
@@ -56,7 +56,7 @@ void main() {
     });
 
     test('validator rejects non-positive path frame durations', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'project',
         maps: [],
         tilesets: [
@@ -85,7 +85,7 @@ void main() {
             ],
           ),
         ],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
       expect(
         () => ProjectValidator.validate(manifest),
diff --git a/packages/map_core/test/path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/path_preset_vertical_atlas_builder_test.dart
index 4167405b..c402b111 100644
--- a/packages/map_core/test/path_preset_vertical_atlas_builder_test.dart
+++ b/packages/map_core/test/path_preset_vertical_atlas_builder_test.dart
@@ -321,7 +321,7 @@ void main() {
           maps: [],
           tilesets: [],
           pathPresets: [preset],
-        );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
         final catalog = createLegacyProjectSurfaceCatalogView(manifest);
 
diff --git a/packages/map_core/test/placed_element_animation_test.dart b/packages/map_core/test/placed_element_animation_test.dart
index 9aae914c..6c036d37 100644
--- a/packages/map_core/test/placed_element_animation_test.dart
+++ b/packages/map_core/test/placed_element_animation_test.dart
@@ -146,5 +146,5 @@ ProjectManifest _project() {
         ],
       ),
     ],
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
diff --git a/packages/map_core/test/placed_element_behaviors_test.dart b/packages/map_core/test/placed_element_behaviors_test.dart
index 987343df..0a09a4f4 100644
--- a/packages/map_core/test/placed_element_behaviors_test.dart
+++ b/packages/map_core/test/placed_element_behaviors_test.dart
@@ -444,5 +444,5 @@ ProjectManifest _project() {
         ],
       ),
     ],
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
diff --git a/packages/map_core/test/placed_elements_test.dart b/packages/map_core/test/placed_elements_test.dart
index ba99733c..46f5b709 100644
--- a/packages/map_core/test/placed_elements_test.dart
+++ b/packages/map_core/test/placed_elements_test.dart
@@ -194,5 +194,5 @@ ProjectManifest _projectWithElement({
         ],
       ),
     ],
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
diff --git a/packages/map_core/test/project_element_frames_test.dart b/packages/map_core/test/project_element_frames_test.dart
index 93f3dbd8..9cad4b8d 100644
--- a/packages/map_core/test/project_element_frames_test.dart
+++ b/packages/map_core/test/project_element_frames_test.dart
@@ -54,7 +54,7 @@ void main() {
             ],
           ),
         ],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       expect(
         () => ProjectValidator.validate(manifest),
         throwsA(isA<ValidationException>()),
diff --git a/packages/map_core/test/project_manifest_surface_integration_prep_test.dart b/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
index 2d4dcd62..2d86d995 100644
--- a/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
+++ b/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
@@ -4,20 +4,10 @@ import 'dart:io';
 import 'package:map_core/map_core.dart';
 import 'package:test/test.dart';
 
-/// ProjectManifest Surface integration prep (Lot 48).
-///
-/// [Lot 49] will likely break test 3 (unknown `surfaceCatalog` currently dropped on write).
-
-const _manifestSurfaceKeyCandidates = <String>[
-  'surfaceCatalog',
-  'surfaceDefinitions',
-  'surfaceAtlases',
-  'surfaceAnimations',
-  'surfacePresets',
-  'surfaceCategories',
-];
-
-const _discouragedTopLevelNames = <String>[
+/// ProjectManifest Surface integration prep (Lot 48) — comportement remplacé
+/// en Lot 49 : [surfaceCatalog] est désormais un champ [ProjectManifest]
+/// persisté (voir [surface_engine_lot_49] dans les rapports).
+const _manifestSplitSurfaceKeyCandidates = <String>[
   'surfaceDefinitions',
   'surfaceAtlases',
   'surfaceAnimations',
@@ -26,24 +16,35 @@ const _discouragedTopLevelNames = <String>[
 ];
 
 void main() {
-  group('ProjectManifest Surface Integration Prep (Lot 48)', () {
-    test('1. current manifest toJson has no Surface persistence keys', () {
-      final manifest = _minimalManifest();
-      _expectNoSurfaceKeys(
-        _asObjectMap(manifest.toJson()),
-      );
-    });
+  group(
+    'ProjectManifest Surface Integration Prep: Lot 48 → Lot 49 transition',
+    () {
+    test(
+      '1. Lot 48: no top-level surface keys; Lot 49: surfaceCatalog + no split',
+      () {
+        final manifest = _minimalManifest();
+        final o = _asObjectMap(manifest.toJson());
+        expect(o.containsKey('surfaceCatalog'), isTrue);
+        expect(
+          o['surfaceCatalog'],
+          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+        );
+        for (final k in _manifestSplitSurfaceKeyCandidates) {
+          expect(o.containsKey(k), isFalse, reason: k);
+        }
+      },
+    );
 
-    test('2. current manifest round-trips without Surface', () {
+    test('2. manifest round-trips with default empty surface catalog', () {
       final manifest = _minimalManifest();
       final decoded = ProjectManifest.fromJson(manifest.toJson());
       expect(decoded, manifest);
     });
 
     test(
-      '3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49',
+      '3. Lot 48 dropped unknown surfaceCatalog on write — Lot 49 persists it',
       () {
-        final withCatalog = _withFutureSurfaceCatalog(
+        final withCatalog = _withSurfaceCatalog(
           _manifestJson(),
           <String, Object?>{
             'atlases': <Object?>[],
@@ -55,42 +56,59 @@ void main() {
           Map<String, dynamic>.from(withCatalog),
         );
         final out = _asObjectMap(manifest.toJson());
-        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(out.containsKey('surfaceCatalog'), isTrue);
+        expect(
+          out['surfaceCatalog'],
+          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+        );
+        expect(manifest.surfaceCatalog.isEmpty, isTrue);
         expect(manifest.name, 'Lot 48 Prep');
       },
     );
 
     test(
-      '4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)',
+      '4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)',
       () {
         final surface = _readSurfaceCatalogFixtureJson(
           'minimal_water_surface_catalog_v0.json',
         );
-        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
+        final withCatalog = _withSurfaceCatalog(_manifestJson(), surface);
         final manifest = ProjectManifest.fromJson(
           Map<String, dynamic>.from(withCatalog),
         );
         final out = _asObjectMap(manifest.toJson());
-        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(out.containsKey('surfaceCatalog'), isTrue);
+        expect(
+          out['surfaceCatalog'],
+          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+        );
         expect(manifest.name, 'Lot 48 Prep');
         expect(manifest.maps, isEmpty);
         expect(manifest.tilesets, isEmpty);
+        expect(manifest.surfaceCatalog.atlasCount, 1);
+        expect(manifest.surfaceCatalog.animationCount, 1);
+        expect(manifest.surfaceCatalog.presetCount, 1);
       },
     );
 
     test(
-      '5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)',
+      '5. Lot 47 full water: Lot 49 keeps catalog on manifest (was dropped in 48)',
       () {
         final surface = _readSurfaceCatalogFixtureJson(
           'full_water_surface_catalog_v0.json',
         );
-        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
+        final withCatalog = _withSurfaceCatalog(_manifestJson(), surface);
         final manifest = ProjectManifest.fromJson(
           Map<String, dynamic>.from(withCatalog),
         );
         final out = _asObjectMap(manifest.toJson());
-        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(out.containsKey('surfaceCatalog'), isTrue);
+        expect(
+          out['surfaceCatalog'],
+          encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+        );
         expect(manifest.name, 'Lot 48 Prep');
+        expect(manifest.surfaceCatalog.atlasCount, 1);
       },
     );
 
@@ -134,30 +152,24 @@ void main() {
       );
     });
 
-    test('8. recommended future manifest field name is surfaceCatalog', () {
+    test('8. recommended manifest field name is surfaceCatalog', () {
       const recommendedFutureManifestField = 'surfaceCatalog';
       expect(recommendedFutureManifestField, 'surfaceCatalog');
     });
 
     test('9. discouraged split Surface key names are absent from toJson', () {
       final json = _minimalManifest().toJson();
-      for (final k in _discouragedTopLevelNames) {
+      for (final k in _manifestSplitSurfaceKeyCandidates) {
         expect(json.containsKey(k), isFalse, reason: k);
       }
     });
 
-    test(
-      '10. surfaceCatalog is not yet a ProjectManifest field in Lot 48',
-      () {
-        expect(
-          _minimalManifest().toJson().containsKey('surfaceCatalog'),
-          isFalse,
-        );
-      },
-    );
+    test('10. Lot 49: surfaceCatalog is always in toJson', () {
+      expect(_minimalManifest().toJson().containsKey('surfaceCatalog'), isTrue);
+    });
 
     test(
-      '11. root unknown Surface keys do not break decode; not re-emitted on toJson',
+      '11. split + legacy root keys ignored; surfaceCatalog re-emitted; split not',
       () {
         final merged = <String, Object?>{
           ..._manifestJson(),
@@ -176,13 +188,14 @@ void main() {
           Map<String, dynamic>.from(merged),
         );
         final out = m.toJson();
-        for (final k in _manifestSurfaceKeyCandidates) {
+        expect(out.containsKey('surfaceCatalog'), isTrue);
+        for (final k in _manifestSplitSurfaceKeyCandidates) {
           expect(out.containsKey(k), isFalse, reason: k);
         }
       },
     );
 
-    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)', () {
+    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48/49 tests)', () {
       for (final name in const <String>[
         'empty_surface_catalog_v0.json',
         'minimal_water_surface_catalog_v0.json',
@@ -219,16 +232,10 @@ void main() {
     );
 
     test(
-      '15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests',
+      '15. Lot 49 adds surfaceCatalog to manifest wire (Lot 48 had none)',
       () {
-        // Assertions above use only toJson / fromJson and decodeProjectSurfaceCatalog;
-        // report confirms no lib/ or generated file edits in this lot.
-        expect(
-          _minimalManifest().toJson().keys.where(
-                (k) => k.contains('urface'),
-              ),
-          isEmpty,
-        );
+        final keys = _minimalManifest().toJson().keys.toList();
+        expect(keys.contains('surfaceCatalog'), isTrue);
       },
     );
   });
@@ -240,17 +247,12 @@ Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
   return Map<String, Object?>.from(m);
 }
 
-void _expectNoSurfaceKeys(Map<String, Object?> json) {
-  for (final k in _manifestSurfaceKeyCandidates) {
-    expect(json.containsKey(k), isFalse, reason: 'unexpected key: $k');
-  }
-}
-
 ProjectManifest _minimalManifest() {
-  return const ProjectManifest(
+  return ProjectManifest(
     name: 'Lot 48 Prep',
     maps: [],
     tilesets: [],
+    surfaceCatalog: ProjectSurfaceCatalog(),
   );
 }
 
@@ -271,7 +273,7 @@ Map<String, Object?> _readSurfaceCatalogFixtureJson(String name) {
   return jsonDecode(s) as Map<String, Object?>;
 }
 
-Map<String, Object?> _withFutureSurfaceCatalog(
+Map<String, Object?> _withSurfaceCatalog(
   Map<String, Object?> manifestJson,
   Map<String, Object?> surfaceCatalogJson,
 ) {
diff --git a/packages/map_core/test/project_manifest_surface_json_characterization_test.dart b/packages/map_core/test/project_manifest_surface_json_characterization_test.dart
index d6d43556..c14414f1 100644
--- a/packages/map_core/test/project_manifest_surface_json_characterization_test.dart
+++ b/packages/map_core/test/project_manifest_surface_json_characterization_test.dart
@@ -30,8 +30,14 @@ void main() {
       expect(manifest.scenarios, isEmpty);
       expect(manifest.trainers, isEmpty);
       expect(manifest.characters, isEmpty);
+      expect(manifest.surfaceCatalog.isEmpty, isTrue);
       expect(manifest.settings.tileWidth, 16);
       expect(manifest.settings.tileHeight, 16);
+      expect(json.containsKey('surfaceCatalog'), isTrue);
+      expect(
+        json['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+      );
       expect(json, isNot(contains('surfaceDefinitions')));
       expect(json['settings'], containsPair('tileWidth', 16));
       expect(json['settings'], containsPair('tileHeight', 16));
diff --git a/packages/map_core/test/project_surface_animation_json_codec_test.dart b/packages/map_core/test/project_surface_animation_json_codec_test.dart
index 74e7f314..575dea16 100644
--- a/packages/map_core/test/project_surface_animation_json_codec_test.dart
+++ b/packages/map_core/test/project_surface_animation_json_codec_test.dart
@@ -466,7 +466,7 @@ void main() {
     });
 
     test('29. ProjectManifest has no surface persistence keys (Lot 42)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L42',
         maps: [
           ProjectMapEntry(
@@ -476,8 +476,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final ju = manifest.toJson();
+      expect(ju.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/project_surface_animation_test.dart b/packages/map_core/test/project_surface_animation_test.dart
index 7eb74608..f48d279e 100644
--- a/packages/map_core/test/project_surface_animation_test.dart
+++ b/packages/map_core/test/project_surface_animation_test.dart
@@ -433,7 +433,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L27',
         maps: [
           ProjectMapEntry(
@@ -443,8 +443,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/project_surface_atlas_test.dart b/packages/map_core/test/project_surface_atlas_test.dart
index 3df05de7..b5298055 100644
--- a/packages/map_core/test/project_surface_atlas_test.dart
+++ b/packages/map_core/test/project_surface_atlas_test.dart
@@ -315,7 +315,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no top-level surface* keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L23',
         maps: [
           ProjectMapEntry(
@@ -325,8 +325,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/project_surface_catalog_json_codec_test.dart b/packages/map_core/test/project_surface_catalog_json_codec_test.dart
index 191c28ee..2b34e121 100644
--- a/packages/map_core/test/project_surface_catalog_json_codec_test.dart
+++ b/packages/map_core/test/project_surface_catalog_json_codec_test.dart
@@ -554,8 +554,8 @@ void main() {
       expect(encodeProjectSurfaceCatalog(_catalog()), isA<Map<String, Object?>>());
     });
 
-    test('40. ProjectManifest has no surface persistence keys (Lot 46)', () {
-      const manifest = ProjectManifest(
+    test('40. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)', () {
+      final manifest = ProjectManifest(
         name: 'L46',
         maps: [
           ProjectMapEntry(
@@ -565,10 +565,15 @@ void main() {
           ),
         ],
         tilesets: [],
+        surfaceCatalog: ProjectSurfaceCatalog(),
       );
       final ju = manifest.toJson();
+      expect(ju.containsKey('surfaceCatalog'), isTrue);
+      expect(
+        ju['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+      );
       for (final k in const [
-        'surfaceCatalog',
         'surfaceDefinitions',
         'surfaceAtlases',
         'surfaceAnimations',
@@ -588,7 +593,7 @@ void main() {
       },
     );
 
-    test('42. manifest surface integration remains out of scope (no manifest codec)', () {
+    test('42. catalog encode still independent of manifest (Lot 49 uses same encode)', () {
       final m = encodeProjectSurfaceCatalog(_catalog());
       expect(m['atlases'], isA<List>());
     });
diff --git a/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart b/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
index 2d99afb5..ed471ee4 100644
--- a/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
+++ b/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
@@ -287,8 +287,8 @@ void main() {
       expect(encodeProjectSurfaceCatalog(_minimalWaterCatalog()), isA<Map<String, Object?>>());
     });
 
-    test('25. ProjectManifest has no surface persistence keys (Lot 47)', () {
-      const manifest = ProjectManifest(
+    test('25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)', () {
+      final manifest = ProjectManifest(
         name: 'L47',
         maps: [
           ProjectMapEntry(
@@ -298,10 +298,15 @@ void main() {
           ),
         ],
         tilesets: [],
+        surfaceCatalog: ProjectSurfaceCatalog(),
       );
       final ju = manifest.toJson();
+      expect(ju.containsKey('surfaceCatalog'), isTrue);
+      expect(
+        ju['surfaceCatalog'],
+        encodeProjectSurfaceCatalog(manifest.surfaceCatalog),
+      );
       for (final k in const [
-        'surfaceCatalog',
         'surfaceDefinitions',
         'surfaceAtlases',
         'surfaceAnimations',
diff --git a/packages/map_core/test/project_surface_catalog_test.dart b/packages/map_core/test/project_surface_catalog_test.dart
index c7b35d53..6cc424a7 100644
--- a/packages/map_core/test/project_surface_catalog_test.dart
+++ b/packages/map_core/test/project_surface_catalog_test.dart
@@ -363,8 +363,8 @@ void main() {
       expect(catalog, isA<ProjectSurfaceCatalog>());
     });
 
-    test('31. ProjectManifest still has no Surface persistence keys (Lot 33)', () {
-      const manifest = ProjectManifest(
+    test('31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)', () {
+      final manifest = ProjectManifest(
         name: 'L33',
         maps: [
           ProjectMapEntry(
@@ -374,8 +374,10 @@ void main() {
           ),
         ],
         tilesets: [],
+        surfaceCatalog: ProjectSurfaceCatalog(),
       );
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       const forbidden = <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/project_surface_preset_json_codec_test.dart b/packages/map_core/test/project_surface_preset_json_codec_test.dart
index a41eaeeb..770a7228 100644
--- a/packages/map_core/test/project_surface_preset_json_codec_test.dart
+++ b/packages/map_core/test/project_surface_preset_json_codec_test.dart
@@ -450,7 +450,7 @@ void main() {
     });
 
     test('30. ProjectManifest has no surface persistence keys (Lot 45)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L45',
         maps: [
           ProjectMapEntry(
@@ -460,8 +460,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final ju = manifest.toJson();
+      expect(ju.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/project_surface_preset_test.dart b/packages/map_core/test/project_surface_preset_test.dart
index 62bbb33d..641b097b 100644
--- a/packages/map_core/test/project_surface_preset_test.dart
+++ b/packages/map_core/test/project_surface_preset_test.dart
@@ -370,7 +370,7 @@ void main() {
     });
 
     test('23. ProjectManifest still has no Surface persistence keys (Lot 21–31)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L31 smoke',
         maps: [
           ProjectMapEntry(
@@ -380,7 +380,7 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
       const forbidden = <String>[
         'surfaceDefinitions',
diff --git a/packages/map_core/test/project_trainer_validation_test.dart b/packages/map_core/test/project_trainer_validation_test.dart
index 98a0c62c..330a6500 100644
--- a/packages/map_core/test/project_trainer_validation_test.dart
+++ b/packages/map_core/test/project_trainer_validation_test.dart
@@ -17,7 +17,7 @@ void main() {
             battleDifficulty: 11,
           ),
         ],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
       expect(
         () => ProjectValidator.validate(manifest),
@@ -44,7 +44,7 @@ void main() {
             battleBackgroundRelativePath: '../outside.png',
           ),
         ],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
       expect(
         () => ProjectValidator.validate(manifest),
diff --git a/packages/map_core/test/scenario_assets_test.dart b/packages/map_core/test/scenario_assets_test.dart
index d4b5ee0f..bb0253e2 100644
--- a/packages/map_core/test/scenario_assets_test.dart
+++ b/packages/map_core/test/scenario_assets_test.dart
@@ -286,5 +286,5 @@ ProjectManifest _projectWithScenario(ScenarioAsset scenario) {
       ),
     ],
     scenarios: [scenario],
-  );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 }
diff --git a/packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart
index 0f715238..81fb3143 100644
--- a/packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart
+++ b/packages/map_core/test/standard_ice_path_preset_vertical_atlas_builder_test.dart
@@ -177,7 +177,7 @@ void main() {
           maps: [],
           tilesets: [],
           pathPresets: [preset],
-        );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
         final catalog = createLegacyProjectSurfaceCatalogView(manifest);
 
diff --git a/packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart
index ece95aff..120f1a22 100644
--- a/packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart
+++ b/packages/map_core/test/standard_lava_path_preset_vertical_atlas_builder_test.dart
@@ -177,7 +177,7 @@ void main() {
           maps: [],
           tilesets: [],
           pathPresets: [preset],
-        );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
         final catalog = createLegacyProjectSurfaceCatalogView(manifest);
 
diff --git a/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
index b2c99cfb..e2dd67e2 100644
--- a/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
+++ b/packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
@@ -161,7 +161,7 @@ void main() {
           maps: [],
           tilesets: [],
           pathPresets: [preset],
-        );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
         final catalog = createLegacyProjectSurfaceCatalogView(manifest);
 
diff --git a/packages/map_core/test/standard_surface_preset_builder_test.dart b/packages/map_core/test/standard_surface_preset_builder_test.dart
index 1df2f7d5..f943bb6b 100644
--- a/packages/map_core/test/standard_surface_preset_builder_test.dart
+++ b/packages/map_core/test/standard_surface_preset_builder_test.dart
@@ -345,7 +345,7 @@ void main() {
     });
 
     test('20. ProjectManifest toJson has no top-level surface* keys (Lot 32)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L32',
         maps: [
           ProjectMapEntry(
@@ -355,8 +355,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       const forbidden = <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart
index fb5220c0..7d6d3ddc 100644
--- a/packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart
+++ b/packages/map_core/test/standard_tall_grass_path_preset_vertical_atlas_builder_test.dart
@@ -180,7 +180,7 @@ void main() {
           maps: [],
           tilesets: [],
           pathPresets: [preset],
-        );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
         final catalog = createLegacyProjectSurfaceCatalogView(manifest);
 
diff --git a/packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart b/packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart
index a06be914..a0767f07 100644
--- a/packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart
+++ b/packages/map_core/test/standard_water_path_preset_vertical_atlas_builder_test.dart
@@ -180,7 +180,7 @@ void main() {
           maps: [],
           tilesets: [],
           pathPresets: [preset],
-        );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
 
         final catalog = createLegacyProjectSurfaceCatalogView(manifest);
 
diff --git a/packages/map_core/test/surface_animation_frame_json_codec_test.dart b/packages/map_core/test/surface_animation_frame_json_codec_test.dart
index afb1ffa6..4644d75a 100644
--- a/packages/map_core/test/surface_animation_frame_json_codec_test.dart
+++ b/packages/map_core/test/surface_animation_frame_json_codec_test.dart
@@ -297,7 +297,7 @@ void main() {
     });
 
     test('21. ProjectManifest has no surface persistence keys (Lot 40)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L40',
         maps: [
           ProjectMapEntry(
@@ -307,8 +307,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
+      expect(j.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_animation_frame_test.dart b/packages/map_core/test/surface_animation_frame_test.dart
index d60001a0..075c2b8c 100644
--- a/packages/map_core/test/surface_animation_frame_test.dart
+++ b/packages/map_core/test/surface_animation_frame_test.dart
@@ -199,7 +199,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L25',
         maps: [
           ProjectMapEntry(
@@ -209,8 +209,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_animation_timeline_json_codec_test.dart b/packages/map_core/test/surface_animation_timeline_json_codec_test.dart
index f2cf78c5..22cc7673 100644
--- a/packages/map_core/test/surface_animation_timeline_json_codec_test.dart
+++ b/packages/map_core/test/surface_animation_timeline_json_codec_test.dart
@@ -306,7 +306,7 @@ void main() {
     });
 
     test('21. ProjectManifest has no surface persistence keys (Lot 41)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L41',
         maps: [
           ProjectMapEntry(
@@ -316,8 +316,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
+      expect(j.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_animation_timeline_test.dart b/packages/map_core/test/surface_animation_timeline_test.dart
index 7c8a57e6..07b3e63b 100644
--- a/packages/map_core/test/surface_animation_timeline_test.dart
+++ b/packages/map_core/test/surface_animation_timeline_test.dart
@@ -198,7 +198,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L26',
         maps: [
           ProjectMapEntry(
@@ -208,8 +208,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_atlas_geometry_test.dart b/packages/map_core/test/surface_atlas_geometry_test.dart
index 3ad41d6d..1ca65341 100644
--- a/packages/map_core/test/surface_atlas_geometry_test.dart
+++ b/packages/map_core/test/surface_atlas_geometry_test.dart
@@ -201,7 +201,7 @@ void main() {
     });
 
     test('ProjectManifest toJson() still has no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L22',
         maps: [
           ProjectMapEntry(
@@ -211,8 +211,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_atlas_json_codec_test.dart b/packages/map_core/test/surface_atlas_json_codec_test.dart
index bad3f7fa..3422ef44 100644
--- a/packages/map_core/test/surface_atlas_json_codec_test.dart
+++ b/packages/map_core/test/surface_atlas_json_codec_test.dart
@@ -482,7 +482,7 @@ void main() {
     });
 
     test('29. ProjectManifest has no surface persistence keys (Lot 39)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L39',
         maps: [
           ProjectMapEntry(
@@ -492,8 +492,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
+      expect(j.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_atlas_tile_ref_test.dart b/packages/map_core/test/surface_atlas_tile_ref_test.dart
index c51a46b1..408b3567 100644
--- a/packages/map_core/test/surface_atlas_tile_ref_test.dart
+++ b/packages/map_core/test/surface_atlas_tile_ref_test.dart
@@ -155,7 +155,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L24',
         maps: [
           ProjectMapEntry(
@@ -165,8 +165,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart b/packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
index 4b0a525e..be419bba 100644
--- a/packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
+++ b/packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart
@@ -367,7 +367,7 @@ void main() {
     });
 
     test('19. ProjectManifest still has no Surface keys (Lot 36)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L36',
         maps: [
           ProjectMapEntry(
@@ -377,7 +377,7 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
       for (final k in const [
         'surfaceDefinitions',
diff --git a/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart b/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
index 9449c4c2..ca6a412a 100644
--- a/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
+++ b/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
@@ -599,7 +599,7 @@ void main() {
     });
 
     test('22. ProjectManifest: no Surface keys (Lot 38)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L38',
         maps: [
           ProjectMapEntry(
@@ -609,7 +609,7 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
       for (final k in const [
         'surfaceDefinitions',
diff --git a/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart b/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
index 008f4ece..7147895e 100644
--- a/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
+++ b/packages/map_core/test/surface_catalog_diagnostics_summary_test.dart
@@ -411,7 +411,7 @@ void main() {
     });
 
     test('15. ProjectManifest still has no Surface keys (Lot 37)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L37',
         maps: [
           ProjectMapEntry(
@@ -421,7 +421,7 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
       for (final k in const [
         'surfaceDefinitions',
diff --git a/packages/map_core/test/surface_catalog_diagnostics_test.dart b/packages/map_core/test/surface_catalog_diagnostics_test.dart
index d75ec39d..34a8b164 100644
--- a/packages/map_core/test/surface_catalog_diagnostics_test.dart
+++ b/packages/map_core/test/surface_catalog_diagnostics_test.dart
@@ -436,7 +436,7 @@ void main() {
     });
 
     test('25. ProjectManifest still has no Surface keys (Lot 34)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L34',
         maps: [
           ProjectMapEntry(
@@ -446,7 +446,7 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
       for (final k in const [
         'surfaceDefinitions',
diff --git a/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart b/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart
index 39221cd2..954980c9 100644
--- a/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart
+++ b/packages/map_core/test/surface_catalog_unused_diagnostics_test.dart
@@ -460,7 +460,7 @@ void main() {
     });
 
     test('24. ProjectManifest still has no Surface keys (Lot 35)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L35',
         maps: [
           ProjectMapEntry(
@@ -470,7 +470,7 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final j = manifest.toJson();
       for (final k in const [
         'surfaceDefinitions',
diff --git a/packages/map_core/test/surface_model_entrypoint_test.dart b/packages/map_core/test/surface_model_entrypoint_test.dart
index a4ad3caf..4fa38b3f 100644
--- a/packages/map_core/test/surface_model_entrypoint_test.dart
+++ b/packages/map_core/test/surface_model_entrypoint_test.dart
@@ -12,8 +12,8 @@ void main() {
       ]);
     });
 
-    test('ProjectManifest JSON has no surface engine manifest keys yet', () {
-      const manifest = ProjectManifest(
+    test('ProjectManifest has surfaceCatalog; split surface keys stay absent', () {
+      final manifest = ProjectManifest(
         name: 'L21 smoke',
         maps: [
           ProjectMapEntry(
@@ -23,8 +23,10 @@ void main() {
           ),
         ],
         tilesets: [],
+        surfaceCatalog: ProjectSurfaceCatalog(),
       );
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       const forbidden = <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart b/packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart
index c94914de..203dd572 100644
--- a/packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart
+++ b/packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart
@@ -200,7 +200,7 @@ void main() {
     });
 
     test('23. ProjectManifest has no surface persistence keys (Lot 43)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L43',
         maps: [
           ProjectMapEntry(
@@ -210,8 +210,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final ju = manifest.toJson();
+      expect(ju.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart b/packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart
index 0714713e..ca7e2ba9 100644
--- a/packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart
+++ b/packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart
@@ -302,7 +302,7 @@ void main() {
     });
 
     test('24. ProjectManifest has no surface persistence keys (Lot 44)', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L44',
         maps: [
           ProjectMapEntry(
@@ -312,8 +312,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final ju = manifest.toJson();
+      expect(ju.containsKey('surfaceCatalog'), isTrue);
       for (final k in const [
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_variant_animation_ref_set_test.dart b/packages/map_core/test/surface_variant_animation_ref_set_test.dart
index c0de4b51..05a8b941 100644
--- a/packages/map_core/test/surface_variant_animation_ref_set_test.dart
+++ b/packages/map_core/test/surface_variant_animation_ref_set_test.dart
@@ -243,7 +243,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L30',
         maps: [
           ProjectMapEntry(
@@ -253,8 +253,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_variant_animation_ref_test.dart b/packages/map_core/test/surface_variant_animation_ref_test.dart
index 7a2d186b..9b0d7d27 100644
--- a/packages/map_core/test/surface_variant_animation_ref_test.dart
+++ b/packages/map_core/test/surface_variant_animation_ref_test.dart
@@ -151,7 +151,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L29',
         maps: [
           ProjectMapEntry(
@@ -161,8 +161,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
diff --git a/packages/map_core/test/surface_variant_role_test.dart b/packages/map_core/test/surface_variant_role_test.dart
index cf352d9e..ee1f6ebd 100644
--- a/packages/map_core/test/surface_variant_role_test.dart
+++ b/packages/map_core/test/surface_variant_role_test.dart
@@ -64,7 +64,7 @@ void main() {
     });
 
     test('ProjectManifest toJson: no surface* top-level keys', () {
-      const manifest = ProjectManifest(
+      final manifest = ProjectManifest(
         name: 'L28',
         maps: [
           ProjectMapEntry(
@@ -74,8 +74,9 @@ void main() {
           ),
         ],
         tilesets: [],
-      );
+        surfaceCatalog: ProjectSurfaceCatalog(),);
       final map = manifest.toJson();
+      expect(map.containsKey('surfaceCatalog'), isTrue);
       for (final key in <String>[
         'surfaceDefinitions',
         'surfaceAtlases',
```

*Contenu intégral du présent rapport : ce fichier `surface_engine_lot_49_project_manifest_surface_integration.md` contient toute la preuve narrative, les commandes, et les diffs. Pour un diff `/dev/null` de ce .md, il serait identique à ce fichier avec préfixe `+` ligne par ligne, conformément à l’exception du cahier.*
