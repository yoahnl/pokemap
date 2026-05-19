# ShadowV2-3 — Projected Building Shadow JSON Characterization / Compatibility Prep

## 1. Résumé exécutif

ShadowV2-3 verrouille le comportement JSON actuel avant tout ajout de modèle V2.

Production:

- aucun code de production modifié;
- aucun modèle V2 ajouté;
- aucun codec de production modifié;
- aucune migration JSON modifiée;
- aucun fichier Selbrume modifié.

Tests ajoutés:

- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`

Caractérisation:

- unknown root keys V2-like: acceptées par `ProjectManifest.fromJson`, supprimées par `toJson`;
- unknown element keys V2-like: acceptées par `ProjectElementEntry.fromJson`, supprimées par `toJson`;
- `migrateProjectManifestJson`: préserve actuellement l'objet par identité, donc conserve les unknown keys;
- Shadow V1 round-trip: stable, aucun champ V2 émis.

Conclusion:

V2 peut être additive et optional, mais il faut des tests de compat dédiés avant l'ajout du modèle. Les champs inconnus ne survivent pas au round-trip model `fromJson -> toJson`; les migrations actuelles, elles, préservent l'entrée brute.

## 2. Objectif du lot

Objectif:

```text
Avant d'ajouter les champs V2 d'ombres projetées,
on verrouille le comportement JSON actuel des projets existants.
```

Question centrale:

```text
Que se passe-t-il aujourd'hui si un project.json contient,
ou ne contient pas,
des champs inconnus liés aux futures ombres projetées V2 ?
```

## 3. Rappel ShadowV2-2

ShadowV2-2 a recommandé:

- `ProjectBuildingShadowPresetCatalog`;
- `ProjectElementProjectedBuildingShadowConfig`;
- Design C maintenant;
- extension future Design D avec optional shadow asset override.

ShadowV2-3 ne crée aucun de ces modèles.

## 4. État initial du worktree

Commande:

```bash
git status --short --untracked-files=all
```

Sortie exacte:

```text
(no output)
```

### Design gate / AGENTS

Commandes:

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie exacte:

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation:

```text
ShadowV2-3 ajoute uniquement des tests de caractérisation.
Le design ShadowV2-1 / ShadowV2-2 existe déjà.
Aucun comportement produit, modèle, codec, migration, runtime ou éditeur n'est modifié.
Le design gate n'est donc pas bloquant pour ces tests.
```

## 5. Fichiers audités

Tous les fichiers demandés existent:

```text
present	reports/shadows/v2/shadow_v2_1_projected_building_shadows_product_spec_art_direction.md
present	reports/shadows/shadow_lot_68_shadow_recovery_closure_projected_building_shadows_v2_roadmap.md
present	reports/shadows/shadow_lot_67_selbrume_shadow_golden_baseline_implementation.md
present	reports/shadows/shadow_lot_66_selbrume_shadow_golden_baseline_design.md
present	packages/map_core/lib/src/models/shadow.dart
present	packages/map_core/lib/src/models/shadow_catalog.dart
present	packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
present	packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
present	packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
present	packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart
present	packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart
present	packages/map_core/lib/src/operations/shadow_config_resolver.dart
present	packages/map_core/lib/src/operations/static_shadow_geometry.dart
present	packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
present	packages/map_core/lib/src/operations/static_shadow_family_projection.dart
present	packages/map_core/lib/src/operations/static_shadow_contact_ledge_geometry.dart
present	packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
present	packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
present	packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
present	packages/map_core/lib/src/models/project_manifest.dart
present	packages/map_core/lib/src/operations/project_json_migrations.dart
present	packages/map_core/lib/src/operations/project_manifest_shadow_catalog_operations.dart
```

Choix du répertoire de test:

```text
packages/map_core/test/shadow_v2/
```

Justification: ShadowV2 est une nouvelle ligne de travail. Le test reste hors `test/shadow/` pour ne pas mélanger les tests V1 avec la préparation V2, tout en restant dans `map_core`.

### Résultats rg des modèles / codecs

Commande demandée:

```bash
rg -n "class ProjectManifest|ProjectManifest\\(|fromJson|toJson|JsonSerializable|Freezed|unknown|ProjectElementEntry|shadowCatalog|shadow" packages/map_core/lib/src/models packages/map_core/lib/src/operations
```

Résultat complet quantitatif:

```text
1823 lignes
```

Lignes décisionnelles exactes utilisées pour ce lot:

```text
packages/map_core/lib/src/models/project_manifest.dart:23:  @ProjectShadowCatalogJsonConverter() ProjectShadowCatalog? shadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:35:factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
packages/map_core/lib/src/models/project_manifest.dart:36:    _$ProjectManifestFromJson(json);
packages/map_core/lib/src/models/project_element.dart:26:class ProjectElementEntry with _$ProjectElementEntry {
packages/map_core/lib/src/models/project_element.dart:40:    @ProjectElementShadowConfigJsonConverter() ProjectElementShadowConfig? shadow,
packages/map_core/lib/src/models/project_element.dart:57:  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
packages/map_core/lib/src/models/project_element.dart:58:      _$ProjectElementEntryFromJson(json);
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart:7:class ProjectElementShadowConfigJsonConverter
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:5:class ProjectShadowCatalogJsonConverter
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:13:  ProjectShadowCatalog fromJson(Object? json) {
packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart:27:  Object? toJson(ProjectShadowCatalog? catalog) {
packages/map_core/lib/src/operations/project_shadow_profile_json_codec.dart:9:class ProjectShadowProfileJsonConverter
```

Conclusion de l'audit:

```text
Le comportement JSON concerné par ShadowV2-3 passe par ProjectManifest, ProjectElementEntry, ProjectShadowCatalog et leurs converters Shadow V1.
Les modèles générés ne conservent pas les unknown keys au round-trip toJson.
```

### Résultats rg des migrations / tests JSON

Commandes demandées:

```bash
rg -n "migrateProjectManifestJson|project.json|schema|version|unknown|shadowCatalog|elements" packages/map_core/lib/src/operations packages/map_core/test
find packages/map_core/test -type f | rg "json|manifest|compat|migration|shadow"
rg -n "ProjectManifest.fromJson|toJson\\(|migrateProjectManifestJson|unknown" packages/map_core/test
```

Résultats complets quantitatifs:

```text
rg migrations/tests JSON: 320 lignes
find tests json/manifest/compat/migration/shadow: 54 fichiers
rg ProjectManifest/fromJson/toJson/migrate/unknown tests: 290 lignes
```

Lignes décisionnelles exactes utilisées pour ce lot:

```text
packages/map_core/lib/src/operations/project_json_migrations.dart:3:Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> json) => json;
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:6:  group('ProjectManifest shadowCatalog JSON', () {
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:6:  group('ProjectElementEntry shadow JSON', () {
packages/map_core/test/shadow/project_shadow_catalog_json_codec_test.dart:6:  group('ProjectShadowCatalog JSON codec', () {
packages/map_core/test/project_json_migrations_test.dart:6:  test('migration leaves legacy manifests unchanged', () {
```

Conclusion de l'audit:

```text
Il existe déjà des tests JSON Shadow V1 ciblés.
Il n'existait pas encore de test ShadowV2 préparant les champs projected building shadow inconnus.
migrateProjectManifestJson conserve actuellement l'objet brut par identité.
```

## 6. Comportement JSON actuel

### ProjectManifest

Audit:

- `ProjectManifest` porte déjà `shadowCatalog`;
- `shadowCatalog` utilise `ProjectShadowCatalogJsonConverter`;
- les champs inconnus ne sont pas réémis par `toJson`;
- les champs requis minimaux observés pour les tests sont `name`, `maps`, `tilesets`.

### ProjectElementEntry

Audit:

- `ProjectElementEntry` a un champ nullable `shadow`;
- `shadow` utilise `ProjectElementShadowConfigJsonConverter`;
- unknown keys élément acceptées par `fromJson`;
- unknown keys élément supprimées par `toJson`.

### ProjectShadowCatalog

Audit:

- catalogue V1 basé sur `profiles`;
- absence/null/objet sans `profiles` décode empty;
- `toJson` réémet uniquement la shape V1;
- pas de champ V2 de preset projeté.

### Migrations

Audit:

- `migrateProjectManifestJson` retourne actuellement l'objet brut par identité;
- les unknown keys sont donc conservées au niveau migration brute;
- elles disparaissent ensuite si le JSON passe par les modèles Freezed/JsonSerializable et `toJson`.

## 7. Tests de caractérisation ajoutés

Test file:

```text
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
```

Tests ajoutés:

1. `ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data`
2. `ProjectElementEntry JSON without projected building shadow keeps no V2 keys after round-trip`
3. `ProjectShadowCatalog JSON remains V1-only and does not emit V2 projected building presets`
4. `unknown root future catalog keys are accepted by ProjectManifest.fromJson and dropped by toJson`
5. `unknown element future projected shadow key is accepted and dropped by ProjectElementEntry.toJson`
6. `migrateProjectManifestJson currently preserves V2-like unknown keys by identity`
7. `Selbrume-like synthetic V1 shadow sample round-trips without V2 keys`

Placed element V2 override unknown key:

- non testé dans ce lot;
- raison: le prompt l'autorise seulement si facile sans élargir;
- recommandation: traiter dans un futur lot dédié aux instance overrides V2.

## 8. Résultats unknown root keys

Résultat:

```text
ProjectManifest.fromJson accepte buildingShadowPresets et projectedBuildingShadowCatalog.
ProjectManifest.toJson les supprime.
Les champs connus restent intacts.
```

Impact:

- Un vieux modèle ne conserve pas les futures clés au round-trip.
- Quand V2 sera ajoutée, il faudra tester explicitement la conservation des nouveaux champs.

## 9. Résultats unknown element keys

Résultat:

```text
ProjectElementEntry.fromJson accepte projectedBuildingShadow.
ProjectElementEntry.toJson le supprime.
La shadow V1 connue reste intacte.
```

Impact:

- Ajouter `projectedBuildingShadow` comme champ optionnel sera backward-compatible.
- Mais tant que le champ n'existe pas, un round-trip supprime cette donnée.

## 10. Résultats migration behavior

Résultat:

```text
migrateProjectManifestJson(raw) retourne actuellement raw par identité.
Les unknown root keys V2-like restent présentes.
Les unknown element keys V2-like restent présentes.
```

Impact:

- La migration brute ne filtre pas les champs futurs.
- La perte éventuelle vient du passage model `fromJson -> toJson`, pas de la migration actuelle.

## 11. Résultats round-trip V1

Résultat:

```text
ProjectManifest sans champs V2 round-trip stable.
ProjectElementEntry.shadow V1 stable.
ProjectShadowCatalog V1 stable.
Synthétique Selbrume-like stable.
Aucun champ V2 émis automatiquement.
```

Champs V2 vérifiés absents:

```text
buildingShadowPresets
projectedBuildingShadow
projectedShadow
buildingProjectedShadow
projectedBuildingShadowCatalog
projectedBuildingShadowPresets
```

## 12. Conclusions compatibilité

Réponses attendues:

1. Unknown root keys acceptées ? Oui.
2. Unknown element keys acceptées ? Oui.
3. Unknown keys conservées au round-trip ? Non, supprimées par `toJson`.
4. `migrateProjectManifestJson` conserve ou supprime ? Conserve par identité.
5. Ajouter V2 comme champs optionnels sera-t-il backward-compatible ? Oui, si additive + defaults null/empty.
6. Migration explicite nécessaire ? Pas forcément pour absence V2; probablement non si defaults suffisent.
7. Peut-on éviter build_runner ? Pas si on touche Freezed models plus tard; oui dans ce lot.
8. Futurs tests golden JSON où ? `packages/map_core/test/shadow_v2/`, puis éventuellement `test/shadow/` quand V2 devient modèle stable.
9. Prochain lot recommandé ? ShadowV2-4 value objects V0.

## 13. Implications pour le futur modèle V2

Futur modèle:

- doit être additive;
- doit être optional;
- doit avoir decode absent -> null/empty;
- ne doit jamais créer d'ombre projetée automatiquement;
- doit avoir tests de round-trip explicites;
- doit tester que V1 sans V2 ne gagne aucun champ V2;
- doit tester que V2 authoré est conservé au round-trip.

Attention:

Avant modèle V2, les données V2-like inconnues sont perdues par `toJson`. C'est normal aujourd'hui, mais doit changer uniquement quand V2 sera explicitement implémentée.

## 14. Tests lancés

Commandes:

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_json_characterization_test.dart
cd packages/map_core && dart test --reporter expanded test/shadow_v2/projected_building_shadow_json_characterization_test.dart
cd packages/map_core && dart test test/shadow/project_manifest_shadow_catalog_json_test.dart test/shadow/project_element_entry_shadow_json_test.dart test/shadow/project_shadow_catalog_json_codec_test.dart test/project_json_migrations_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze test/shadow_v2/projected_building_shadow_json_characterization_test.dart
```

## 15. Résultats des tests

### Test ciblé, sortie complète

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_json_characterization_test.dart
00:00 +0: ShadowV2 projected building shadow JSON characterization ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data
00:00 +1: ShadowV2 projected building shadow JSON characterization ProjectElementEntry JSON without projected building shadow keeps no V2 keys after round-trip
00:00 +2: ShadowV2 projected building shadow JSON characterization ProjectShadowCatalog JSON remains V1-only and does not emit V2 projected building presets
00:00 +3: ShadowV2 projected building shadow JSON characterization unknown root future catalog keys are accepted by ProjectManifest.fromJson and dropped by toJson
00:00 +4: ShadowV2 projected building shadow JSON characterization unknown element future projected shadow key is accepted and dropped by ProjectElementEntry.toJson
00:00 +5: ShadowV2 projected building shadow JSON characterization migrateProjectManifestJson currently preserves V2-like unknown keys by identity
00:00 +6: ShadowV2 projected building shadow JSON characterization Selbrume-like synthetic V1 shadow sample round-trips without V2 keys
00:00 +7: All tests passed!
```

### Tests JSON / migration existants

```text
00:00 +34: All tests passed!
```

### Régression shadow

```text
00:00 +284: All tests passed!
```

## 16. Résultat analyze

Commande:

```bash
cd packages/map_core && dart analyze test/shadow_v2/projected_building_shadow_json_characterization_test.dart
```

Sortie:

```text
Analyzing projected_building_shadow_json_characterization_test.dart...
No issues found!
```

## 17. git diff --stat

Avant et après rapport, les nouveaux fichiers sont untracked, donc `git diff --stat` ne les liste pas.

```text
(no output)
```

## 18. git diff --name-status

```text
(no output)
```

## 19. git diff --check

```text
(no output)
```

## 20. git status final

Sortie finale vérifiée après création de ce rapport:

```text
?? packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
?? reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md
```

## 21. Risques / réserves

- Le test placed element override V2-like n'est pas couvert dans ce lot.
- `migrateProjectManifestJson` préserve par identité aujourd'hui; si une migration future copie/filtre, il faudra re-caractériser.
- Les champs inconnus sont acceptés mais pas conservés par round-trip model.
- Le futur ajout V2 dans Freezed demandera probablement `build_runner`; ce lot ne le lance pas.

## 22. Auto-critique

Le lot verrouille bien le point critique: ce que le JSON fait avant V2. Les tests sont volontairement synthétiques pour éviter de dépendre de Selbrume réel. La limite principale est l'absence de caractérisation des overrides placés, que je recommande de traiter seulement quand le design d'overrides V2 sera validé.

## 23. Regard critique sur le prompt

Le prompt est serré et utile. Il empêche le piège classique: ajouter directement les modèles au lieu de tester le contrat actuel. La distinction migration brute vs round-trip model est le résultat le plus important.

## 24. Prochain lot recommandé

```text
ShadowV2-4 — Projected Building Shadow Value Objects V0
```

Pourquoi:

- le JSON V1 est maintenant caractérisé;
- on peut ajouter des objets purs V2 sans manifest integration;
- il faudra encore éviter codecs/manifest/runtime dans V2-4.

## 25. Code complet du test créé

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ShadowV2 projected building shadow JSON characterization', () {
    test(
      'ProjectManifest JSON without projected building shadow fields '
      'round-trips unchanged for known Shadow V1 data',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: _shadowCatalogJson(),
            elements: <Object?>[
              _elementJson(id: 'house_01', shadow: _buildingShadowJson()),
              _elementJson(id: 'crate_01'),
            ],
          ),
        );

        final json = _wireJson(manifest.toJson());
        final house =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>()[0];
        final crate =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>()[1];

        expect(json['shadowCatalog'], _shadowCatalogJson());
        expect(house['shadow'], _buildingShadowJson());
        expect(crate, containsPair('shadow', null));
        _expectNoV2Keys(json);
        _expectNoV2Keys(house);
        _expectNoV2Keys(crate);
      },
    );

    test(
      'ProjectElementEntry JSON without projected building shadow keeps no V2 '
      'keys after round-trip',
      () {
        final element = ProjectElementEntry.fromJson(
          _elementJson(shadow: _buildingShadowJson()),
        );

        final json = _wireJson(element.toJson());

        expect(json['shadow'], _buildingShadowJson());
        _expectNoV2Keys(json);
      },
    );

    test(
      'ProjectShadowCatalog JSON remains V1-only and does not emit V2 '
      'projected building presets',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(shadowCatalog: _shadowCatalogJson()),
        );

        final catalogJson =
            _wireJson(manifest.toJson())['shadowCatalog'] as Map<String, Object?>;

        expect(catalogJson, _shadowCatalogJson());
        _expectNoV2Keys(catalogJson);
      },
    );

    test(
      'unknown root future catalog keys are accepted by ProjectManifest.fromJson '
      'and dropped by toJson',
      () {
        final raw = _manifestJson(
          shadowCatalog: _shadowCatalogJson(),
          extraRoot: <String, Object?>{
            'buildingShadowPresets': <Object?>[],
            'projectedBuildingShadowCatalog': <String, Object?>{
              'presets': <Object?>[],
            },
          },
        );

        final manifest = ProjectManifest.fromJson(raw);
        final json = _wireJson(manifest.toJson());

        expect(raw, contains('buildingShadowPresets'));
        expect(raw, contains('projectedBuildingShadowCatalog'));
        expect(json, isNot(contains('buildingShadowPresets')));
        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
        expect(json['shadowCatalog'], _shadowCatalogJson());
      },
    );

    test(
      'unknown element future projected shadow key is accepted and dropped by '
      'ProjectElementEntry.toJson',
      () {
        final raw = _elementJson(
          shadow: _buildingShadowJson(),
          extra: <String, Object?>{
            'projectedBuildingShadow': <String, Object?>{
              'enabled': true,
              'presetId': 'short-west-building-shadow',
            },
          },
        );

        final element = ProjectElementEntry.fromJson(raw);
        final json = _wireJson(element.toJson());

        expect(raw, contains('projectedBuildingShadow'));
        expect(json, isNot(contains('projectedBuildingShadow')));
        expect(json['shadow'], _buildingShadowJson());
      },
    );

    test(
      'migrateProjectManifestJson currently preserves V2-like unknown keys by '
      'identity',
      () {
        final raw = _manifestJson(
          elements: <Object?>[
            _elementJson(
              extra: <String, Object?>{
                'projectedBuildingShadow': <String, Object?>{
                  'enabled': true,
                  'presetId': 'short-west-building-shadow',
                },
              },
            ),
          ],
          extraRoot: <String, Object?>{
            'buildingShadowPresets': <Object?>[],
            'projectedBuildingShadowCatalog': <String, Object?>{
              'presets': <Object?>[],
            },
          },
        );

        final migrated = migrateProjectManifestJson(raw);
        final elements = migrated['elements'] as List<Object?>;
        final element = elements.single! as Map<String, Object?>;

        expect(identical(migrated, raw), isTrue);
        expect(migrated, contains('buildingShadowPresets'));
        expect(migrated, contains('projectedBuildingShadowCatalog'));
        expect(element, contains('projectedBuildingShadow'));
      },
    );

    test(
      'Selbrume-like synthetic V1 shadow sample round-trips without V2 keys',
      () {
        final manifest = ProjectManifest.fromJson(
          _manifestJson(
            shadowCatalog: _shadowCatalogJson(),
            elements: <Object?>[
              _elementJson(id: 'selbrum_maison_test', shadow: _buildingShadowJson()),
              _elementJson(id: 'decor_without_shadow'),
              _elementJson(id: 'decor_shadow_null', shadow: null),
            ],
          ),
        );

        final json = _wireJson(manifest.toJson());
        final elements =
            (json['elements'] as List<Object?>).cast<Map<String, Object?>>();

        expect(elements[0]['shadow'], _buildingShadowJson());
        expect(elements[1], containsPair('shadow', null));
        expect(elements[2], containsPair('shadow', null));
        _expectNoV2Keys(json);
        for (final element in elements) {
          _expectNoV2Keys(element);
        }
      },
    );
  });
}

Map<String, Object?> _manifestJson({
  Object? shadowCatalog = _absent,
  List<Object?>? elements,
  Map<String, Object?> extraRoot = const <String, Object?>{},
}) {
  return <String, Object?>{
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    if (!identical(shadowCatalog, _absent)) 'shadowCatalog': shadowCatalog,
    if (elements != null) 'elements': elements,
    ...extraRoot,
  };
}

Map<String, Object?> _elementJson({
  String id = 'house_01',
  Object? shadow = _absent,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return <String, Object?>{
    'id': id,
    'name': id,
    'tilesetId': 'tileset',
    'categoryId': 'building',
    'frames': <Object?>[
      <String, Object?>{
        'source': <String, Object?>{'x': 0, 'y': 0},
      },
    ],
    if (!identical(shadow, _absent)) 'shadow': shadow,
    ...extra,
  };
}

Map<String, Object?> _shadowCatalogJson() {
  return <String, Object?>{
    'profiles': <Object?>[
      <String, Object?>{
        'id': 'default-ground-wide-ellipse',
        'name': 'Default ground wide ellipse',
        'mode': 'ellipse',
        'renderPass': 'groundStatic',
        'offsetX': 0.0,
        'offsetY': 0.0,
        'scaleX': 1.0,
        'scaleY': 1.0,
        'opacity': 0.18,
        'colorHexRgb': '000000',
        'softnessMode': 'hardEdge',
      },
    ],
  };
}

Map<String, Object?> _buildingShadowJson() {
  return <String, Object?>{
    'castsShadow': true,
    'shadowProfileId': 'default-ground-wide-ellipse',
    'family': 'building',
    'footprint': <String, Object?>{
      'anchorXRatio': 0.5,
      'anchorYRatio': 1.0,
      'footprintWidthRatio': 0.75,
      'footprintHeightRatio': 0.25,
    },
  };
}

Map<String, Object?> _wireJson(Map<String, dynamic> json) {
  return (jsonDecode(jsonEncode(json)) as Map<String, dynamic>)
      .cast<String, Object?>();
}

void _expectNoV2Keys(Map<String, Object?> json) {
  for (final key in _v2Keys) {
    expect(json, isNot(contains(key)), reason: 'unexpected V2 key: $key');
  }
}

const _absent = Object();

const _v2Keys = <String>{
  'buildingShadowPresets',
  'projectedBuildingShadow',
  'projectedShadow',
  'buildingProjectedShadow',
  'projectedBuildingShadowCatalog',
  'projectedBuildingShadowPresets',
};
```

## 26. Inventaire des fichiers

Créés:

- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`
- `reports/shadows/v2/shadow_v2_3_projected_building_shadow_json_characterization.md`

Modifiés:

- Aucun fichier suivi existant.

Supprimés:

- Aucun.

Code de production modifié:

- Aucun.

Fichiers Selbrume modifiés:

- Aucun.

Generated files:

- Aucun.

Commit:

- Aucun.
