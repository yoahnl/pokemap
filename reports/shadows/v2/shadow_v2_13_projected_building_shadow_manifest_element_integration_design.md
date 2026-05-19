# ShadowV2-13 — Projected Building Shadow Manifest / Element Integration Design

## 1. Résumé exécutif

ShadowV2-13 est un design gate uniquement. Aucun code, test, modèle, codec, migration, runtime, éditeur, fichier Selbrume, baseline screenshot ou fichier généré n'a été modifié.

Décision canonique :

- `ProjectManifest` recevra un champ Dart non-nullable `projectedBuildingShadowCatalog` de type `ProjectBuildingShadowPresetCatalog`.
- Le JSON root restera `projectedBuildingShadowCatalog`.
- L'absence du root et `projectedBuildingShadowCatalog: null` décoderont vers un catalogue vide en mémoire.
- Un catalogue vide ne devra pas être émis par `toJson`.
- `ProjectElementEntry` recevra un champ Dart nullable `projectedBuildingShadow` de type `ProjectElementProjectedBuildingShadowConfig?`.
- Le JSON élément restera `projectedBuildingShadow`.
- L'absence du champ élément et `projectedBuildingShadow: null` décoderont vers `null`.
- `toJson` omettra `projectedBuildingShadow` quand la valeur Dart est `null`.
- Les migrations ne devront pas injecter de catalogue, de preset ou de config élément V2.
- Le prochain lot recommandé est un lot unique de persistance, `ShadowV2-14`, intégrant `ProjectManifest` et `ProjectElementEntry` ensemble, avec génération Freezed ciblée dans `map_core`.

## 2. Objectif du lot

Préparer l'intégration future des données ShadowV2 dans `project.json` sans encore toucher au code :

- définir le champ manifest ;
- définir le champ élément ;
- trancher absence / null / empty ;
- préserver la compatibilité des anciens projets ;
- empêcher toute création automatique d'ombre projetée V2 ;
- cadrer les tests JSON et golden fixtures ;
- proposer le prompt précis du prochain lot d'implémentation.

## 3. Rappel ShadowV2-12

ShadowV2-12 a créé uniquement le codec JSON manuel de `ProjectElementProjectedBuildingShadowConfig`.

Les briques disponibles avant intégration sont :

- `ProjectedShadowDirection`
- `ProjectedShadowAnchor`
- `ProjectedShadowOffset`
- `ProjectedShadowShapeTuning`
- `ProjectedShadowAppearance`
- `ProjectedShadowTimeOfDayMode`
- `ProjectBuildingShadowPreset`
- `ProjectBuildingShadowPresetCatalog`
- `ProjectElementProjectedBuildingShadowConfig`
- codec atomique ShadowV2
- codec `ProjectBuildingShadowPreset`
- codec `ProjectBuildingShadowPresetCatalog`
- codec `ProjectElementProjectedBuildingShadowConfig`

ShadowV2-12 rappelle explicitement que l'absence de `projectedBuildingShadow` doit rester `null`.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text

```

Le worktree était propre avant la création du présent rapport.

## 5. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

- Le lot est explicitement design-only.
- Le design gate est respecté par la production d'un rapport sans implémentation.
- Aucune compétence d'implémentation, modification de code ou génération n'a été déclenchée.

## 6. Fichiers audités

Modèles :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/lib/src/models/shadow.dart`
- `packages/map_core/lib/src/models/shadow_catalog.dart`

Note d'audit :

- Le chemin demandé `packages/map_core/lib/src/models/project_element.dart` n'existe pas.
- `ProjectElementEntry` est défini dans `packages/map_core/lib/src/models/project_manifest.dart`.

Opérations JSON / migrations :

- `packages/map_core/lib/src/operations/project_json_migrations.dart`
- `packages/map_core/lib/src/operations/project_shadow_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`

Tests et rapports :

- `packages/map_core/test/project_manifest_surface_integration_test.dart`
- `packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart`
- `packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart`
- `packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart`
- `packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart`
- `reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md`
- `reports/shadows/v2/shadow_v2_12_project_element_projected_building_shadow_config_json_codec.md`

## 7. Audit ProjectManifest actuel

Commande ciblée :

```bash
rg -n "factory ProjectManifest|surfaceCatalog|shadowCatalog|ProjectManifest\.fromJson|ProjectManifest\(" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart packages/map_core/test/project_manifest_surface_integration_test.dart packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
```

Résultat :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:12:        final manifest = ProjectManifest.fromJson(
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:14:            shadowCatalog: _shadowCatalogJson(),
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:28:        expect(json['shadowCatalog'], _shadowCatalogJson());
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:56:        final manifest = ProjectManifest.fromJson(
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:57:          _manifestJson(shadowCatalog: _shadowCatalogJson()),
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:61:            _wireJson(manifest.toJson())['shadowCatalog'] as Map<String, Object?>;
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:63:        expect(catalogJson, _shadowCatalogJson());
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:69:      'unknown root future catalog keys are accepted by ProjectManifest.fromJson '
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:73:          shadowCatalog: _shadowCatalogJson(),
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:82:        final manifest = ProjectManifest.fromJson(raw);
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:89:        expect(json['shadowCatalog'], _shadowCatalogJson());
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:153:        final manifest = ProjectManifest.fromJson(
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:155:            shadowCatalog: _shadowCatalogJson(),
packages/map_core/test/project_manifest_surface_integration_test.dart:9:    test('1. ProjectManifest exposes surfaceCatalog', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:11:      expect(m.surfaceCatalog.isEmpty, isTrue);
packages/map_core/test/project_manifest_surface_integration_test.dart:14:    test('2. toJson encodes surfaceCatalog even when empty', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:24:    test('3. fromJson accepts missing surfaceCatalog key', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:40:    test('4. fromJson accepts surfaceCatalog: null as empty', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:51:    test('5. fromJson rejects surfaceCatalog when not a JSON object', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:64:    test('6. fromJson rejects incomplete surfaceCatalog (missing presets)', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:147:    test('12. copyWith preserves surfaceCatalog when renaming', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:155:    test('13. copyWith can replace surfaceCatalog', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:165:    test('14. equality distinguishes surfaceCatalog', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:175:    test('15. toJson surfaceCatalog matches encodeProjectSurfaceCatalog', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:7:  group('ProjectManifest.shadowCatalog JSON', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:8:    test('decodes legacy manifest JSON without shadowCatalog as empty', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:16:      for (final shadowCatalog in <Object?>[
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:31:      final manifest = ProjectManifest.fromJson(
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:49:      final manifest = _manifest(shadowCatalog: _catalog());
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:57:      expect(json['shadowCatalog'], <String, Object?>{
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:62:    test('copyWith replaces shadowCatalog', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:156:    test('preserves ProjectElementEntry.shadow alongside shadowCatalog', () {
packages/map_core/lib/src/models/project_manifest.dart:27:/// JSON → [ProjectSurfaceCatalog] pour [ProjectManifest.surfaceCatalog] (Lot 49).
packages/map_core/lib/src/models/project_manifest.dart:90:  factory ProjectManifest({
packages/map_core/lib/src/models/project_manifest.dart:128:      name: 'surfaceCatalog',
packages/map_core/lib/src/models/project_manifest.dart:132:    required ProjectSurfaceCatalog surfaceCatalog,
packages/map_core/lib/src/models/project_manifest.dart:135:    ProjectShadowCatalog shadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:138:  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
```

Lecture du modèle :

```text
ProjectManifest est un modèle Freezed avec @JsonSerializable(explicitToJson: true).
surfaceCatalog est required en Dart avec un JsonKey fromJson/toJson manuel.
shadowCatalog utilise @Default(ProjectShadowCatalog.empty()) et un converter.
ProjectManifest.fromJson délègue à _$ProjectManifestFromJson.
```

Conséquences pour l'intégration future :

- L'ajout d'un champ à `ProjectManifest` demandera de mettre à jour les fichiers générés `project_manifest.freezed.dart` et `project_manifest.g.dart`.
- Le prochain lot d'implémentation devra donc lancer `dart run build_runner build --delete-conflicting-outputs` dans `packages/map_core`.
- `copyWith`, égalité et sérialisation générée doivent être couverts par tests après génération.

## 8. Audit ProjectElementEntry actuel

Commande ciblée :

```bash
rg -n "class ProjectElementEntry|ProjectElementEntry\(|ProjectElementEntry\.fromJson|shadow:|containsPair\('shadow'|projectedBuildingShadow" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
```

Résultat :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:16:              _elementJson(id: 'house_01', shadow: _buildingShadowJson()),
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:30:        expect(crate, containsPair('shadow', null));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:41:        final element = ProjectElementEntry.fromJson(
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:42:          _elementJson(shadow: _buildingShadowJson()),
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:76:            'projectedBuildingShadowCatalog': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:86:        expect(raw, contains('projectedBuildingShadowCatalog'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:88:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:98:          shadow: _buildingShadowJson(),
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:100:            'projectedBuildingShadow': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:107:        final element = ProjectElementEntry.fromJson(raw);
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:110:        expect(raw, contains('projectedBuildingShadow'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:111:        expect(json, isNot(contains('projectedBuildingShadow')));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:124:                'projectedBuildingShadow': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:133:            'projectedBuildingShadowCatalog': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:145:        expect(migrated, contains('projectedBuildingShadowCatalog'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:146:        expect(element, contains('projectedBuildingShadow'));
packages/map_core/lib/src/models/project_manifest.dart:368:class ProjectElementEntry with _$ProjectElementEntry {
packages/map_core/lib/src/models/project_manifest.dart:370:  const factory ProjectElementEntry({
packages/map_core/lib/src/models/project_manifest.dart:389:  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:9:      final element = ProjectElementEntry.fromJson(_elementJson());
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:15:      final element = ProjectElementEntry.fromJson(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:16:        _elementJson(shadow: null),
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:23:      final element = ProjectElementEntry.fromJson(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:25:          shadow: <String, Object?>{'castsShadow': false},
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:33:      final element = ProjectElementEntry.fromJson(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:35:          shadow: <String, Object?>{
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:49:        shadow: ProjectElementShadowConfig(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:74:      expect(json, containsPair('shadow', null));
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:82:      final updated = _element().copyWith(shadow: shadow);
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:106:            shadow: ProjectElementShadowConfig(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:136:      final updated = element.copyWith(shadow: shadow);
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:163:  return ProjectElementEntry(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:174:    shadow: shadow,
```

Lecture du modèle :

```text
ProjectElementEntry est défini dans project_manifest.dart.
Il est Freezed avec @JsonSerializable(explicitToJson: true).
Le champ V1 shadow est nullable et utilise @ProjectElementShadowConfigJsonConverter().
ProjectElementEntry.fromJson applique jsonCoerceLegacySourceToFrames puis délègue à _$ProjectElementEntryFromJson.
```

Point de compatibilité important :

- Le V1 `shadow` nullable est actuellement émis comme `"shadow": null`.
- La décision ShadowV2-8 exige une règle différente pour V2 : `projectedBuildingShadow == null` doit omettre le champ.
- Le prochain lot devra donc utiliser `includeIfNull: false` ou une stratégie équivalente pour le champ V2, sans modifier le comportement V1.

## 9. Décisions ProjectManifest

### 9.1 Champ Dart

Décision :

```dart
final ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog;
```

Justification :

- nom aligné avec le champ JSON validé en ShadowV2-8 ;
- explicite sur `projected`, `building` et `shadow` ;
- distinct de `shadowCatalog` V1 ;
- lisible pour une future UI d'authoring ;
- évite d'enfouir V2 dans le catalogue V1.

### 9.2 Nullable ou non-nullable

Décision :

```dart
ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog
```

non-nullable.

Justification :

- ShadowV2-8 a décidé : absence root -> catalogue vide en mémoire ;
- un catalogue vide est une valeur domaine valide ;
- évite des null checks partout dans les futures opérations ;
- rend les tests de compatibilité plus explicites.

### 9.3 Constructeur / default

Décision recommandée :

- ajouter un constructeur vide const à `ProjectBuildingShadowPresetCatalog` si nécessaire ;
- utiliser un default Freezed pour ne pas casser les constructions existantes de `ProjectManifest`.

Forme cible probable :

```dart
@Default(ProjectBuildingShadowPresetCatalog.empty())
@JsonKey(
  name: 'projectedBuildingShadowCatalog',
  fromJson: _projectedBuildingShadowCatalogFromJson,
  toJson: _projectedBuildingShadowCatalogToJson,
  includeIfNull: false,
)
ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog,
```

Réserve technique :

- `ProjectBuildingShadowPresetCatalog` possède aujourd'hui un constructeur non-const avec copie défensive.
- Pour un `@Default(...)` Freezed propre, le prochain lot devra probablement ajouter :

```dart
const ProjectBuildingShadowPresetCatalog.empty() : _presets = const [];
```

- Cette mini-évolution reste dans le modèle domaine existant et ne crée pas de preset par défaut.

### 9.4 `copyWith`

Décision :

```text
Oui, copyWith doit inclure projectedBuildingShadowCatalog.
```

Justification :

- `ProjectManifest` est Freezed ;
- les champs persistants doivent être remplaçables dans les tests et opérations futures ;
- les tests existants couvrent déjà ce comportement pour `surfaceCatalog` et `shadowCatalog`.

### 9.5 `toJson`

Décision :

```text
catalogue vide -> omettre projectedBuildingShadowCatalog
catalogue non vide -> émettre projectedBuildingShadowCatalog: { "presets": [...] }
```

Justification :

- décision canonique ShadowV2-8 ;
- évite de polluer les anciens projets avec une structure V2 vide ;
- respecte la règle fondamentale : aucun projet existant ne gagne une ombre V2 automatiquement ;
- le codec catalogue continue d'encoder un catalogue vide comme `{ "presets": [] }` quand il est appelé directement, mais l'intégration manifest choisit de ne pas appeler ce root en sortie si le catalogue est vide.

### 9.6 `fromJson`

Décision :

```text
projectedBuildingShadowCatalog absent -> ProjectBuildingShadowPresetCatalog vide
projectedBuildingShadowCatalog null -> ProjectBuildingShadowPresetCatalog vide
projectedBuildingShadowCatalog objet -> decodeProjectBuildingShadowPresetCatalog(...)
projectedBuildingShadowCatalog non-objet -> ValidationException
projectedBuildingShadowCatalog {} -> ValidationException
```

Justification :

- absence/null au niveau manifest sont des règles de compatibilité ;
- si l'objet catalogue est présent, le codec catalogue V2-11 exige explicitement `presets` ;
- accepter `{}` au niveau catalogue introduirait un second JSON canonique inutile.

## 10. Décisions ProjectElementEntry

### 10.1 Champ Dart

Décision :

```dart
final ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow;
```

Justification :

- nom aligné avec le champ JSON validé en ShadowV2-8 ;
- distinct du champ V1 `shadow` ;
- exprime clairement que l'ombre projetée V2 est opt-in et authorée.

### 10.2 Nullable ou non-nullable

Décision :

```text
nullable.
```

Sémantique :

```text
null = aucune ombre projetée V2 authorée pour cet élément.
```

Justification :

- absence élément -> null ;
- pas de config disabled implicite ;
- pas de `presetId` magique ;
- évite de polluer tous les éléments existants avec une config V2 vide.

### 10.3 Constructeur / default

Décision :

```dart
ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
```

sans `@Default`.

Justification :

- un paramètre nullable optionnel ne casse pas les appels existants ;
- `null` est le comportement voulu pour les anciens éléments ;
- le modèle `ProjectElementProjectedBuildingShadowConfig` exige `presetId`, `anchor` et `localOffset`, donc un default automatique serait artificiel.

### 10.4 `copyWith`

Décision :

```text
Oui, copyWith doit inclure projectedBuildingShadow.
```

Justification :

- `ProjectElementEntry` est Freezed ;
- le champ devient une donnée persistante ;
- les futurs tests de round-trip et de coexistence V1/V2 doivent pouvoir construire des variantes facilement.

### 10.5 `toJson`

Décision :

```text
projectedBuildingShadow == null -> omettre le champ
projectedBuildingShadow != null -> émettre projectedBuildingShadow
```

Justification :

- décision canonique ShadowV2-8 ;
- évite `"projectedBuildingShadow": null` dans les projets sans V2 ;
- préserve la différence entre "aucune config authorée" et "config authorée mais disabled".

### 10.6 `fromJson`

Décision :

```text
champ absent -> null
champ null -> null
champ objet -> decodeProjectElementProjectedBuildingShadowConfig(...)
champ non-objet -> ValidationException
```

Justification :

- absence et null sont des formes de compatibilité ;
- si l'objet est présent, la config doit être explicitement complète ;
- aucun default silencieux pour `enabled`, `presetId`, `anchor` ou `localOffset`.

### 10.7 V1/V2 coexistence

Décision :

```text
Un élément peut techniquement avoir shadow V1 et projectedBuildingShadow V2 en même temps.
```

Justification :

- la coexistence peut être explicitement authorée ;
- le modèle pur ne doit pas interdire une combinaison tant que le produit n'a pas défini une règle visuelle stricte ;
- les diagnostics et l'éditeur pourront alerter plus tard sur une double ombre trop visible ;
- aucune ombre V2 ne doit être dérivée automatiquement de `shadow` V1.

## 11. Décisions migrations

Décision :

```text
Option A — aucune modification de migrateProjectManifestJson pour ShadowV2 initial.
```

Conséquences :

- `project_json_migrations.dart` ne doit pas injecter `projectedBuildingShadowCatalog`.
- Les migrations ne doivent pas créer de presets V2.
- Les migrations ne doivent pas ajouter `projectedBuildingShadow` aux éléments.
- L'absence est gérée au decode par `ProjectManifest.fromJson` et `ProjectElementEntry.fromJson`.

Justification :

- V2 est additive ;
- aucun projet existant ne doit être muté pour ajouter V2 ;
- ShadowV2-3 a caractérisé que les clés inconnues V2-like sont actuellement conservées par migration brute mais supprimées par `toJson` ;
- une fois l'intégration implémentée, ces clés ne seront plus inconnues et devront round-tripper via les modèles.

## 12. Décisions tests JSON

Tests requis pour le prochain lot :

1. Manifest sans V2 :
   - `ProjectManifest.fromJson` sans `projectedBuildingShadowCatalog` produit un catalogue vide en mémoire ;
   - `toJson` omet `projectedBuildingShadowCatalog`.

2. Manifest avec `projectedBuildingShadowCatalog: null` :
   - decode vers catalogue vide ;
   - `toJson` omet le root.

3. Manifest avec catalogue vide explicite :
   - `{ "projectedBuildingShadowCatalog": { "presets": [] } }` decode vers catalogue vide ;
   - `toJson` omet le root.

4. Manifest avec catalogue V2 non vide :
   - les presets sont préservés ;
   - l'ordre est préservé ;
   - `toJson` émet `projectedBuildingShadowCatalog`.

5. Manifest avec catalogue incomplet :
   - `{ "projectedBuildingShadowCatalog": {} }` est rejeté.

6. Element sans V2 :
   - `ProjectElementEntry.fromJson` sans `projectedBuildingShadow` produit `null` ;
   - `toJson` omet `projectedBuildingShadow`.

7. Element avec `projectedBuildingShadow: null` :
   - decode vers `null` ;
   - `toJson` omet le champ.

8. Element avec config V2 :
   - `ProjectElementEntry.fromJson` decode la config ;
   - `toJson` réémet la config canonique.

9. Element V1 + V2 :
   - `shadow` V1 et `projectedBuildingShadow` V2 round-trippent tous les deux.

10. Compatibilité anciens projets :
   - les fixtures existantes sans V2 restent inchangées, hors comportement déjà connu des champs générés existants.

11. Unknown keys :
   - `projectedBuildingShadowCatalog` et `projectedBuildingShadow` ne sont plus inconnus et sont préservés ;
   - les autres unknown keys gardent le comportement caractérisé par ShadowV2-3.

## 13. Golden JSON fixture strategy

Décision :

```text
Inline JSON pour les tests ciblés ProjectElementEntry.
Fichiers fixtures pour les golden ProjectManifest complets.
```

Fixtures recommandées :

```text
packages/map_core/test/fixtures/shadow_v2/project_manifest_without_projected_building_shadow_v2.json
packages/map_core/test/fixtures/shadow_v2/project_manifest_with_projected_building_shadow_v2.json
packages/map_core/test/fixtures/shadow_v2/project_manifest_with_projected_building_shadow_v2_empty_catalog.json
```

Raison :

- les tests élément restent petits et lisibles inline ;
- les manifests complets bénéficient de fixtures stables ;
- les fixtures golden rendent visible la décision "root vide omis".

## 14. Implementation lot split

Options évaluées :

- Option A : `ShadowV2-14` intègre `ProjectManifest` + `ProjectElementEntry`.
- Option B : `ShadowV2-14` intègre l'élément, puis `ShadowV2-15` le manifest.
- Option C : `ShadowV2-14` intègre le manifest, puis `ShadowV2-15` l'élément.

Décision :

```text
Option A — un lot unique de persistance ProjectManifest + ProjectElementEntry.
```

Justification :

- les deux modèles sont dans le même fichier source `project_manifest.dart` ;
- les deux changements nécessitent la même passe de génération Freezed/json_serializable ;
- scinder provoquerait deux vagues de churn dans `project_manifest.freezed.dart` et `project_manifest.g.dart` ;
- un lot unique reste acceptable si le périmètre est strictement persistence-only ;
- cela évite un état intermédiaire où les éléments peuvent référencer un preset sans catalogue ou inversement.

Contraintes du lot suivant :

- pas de runtime ;
- pas d'éditeur ;
- pas de renderer ;
- pas de migration injective ;
- pas de preset par défaut ;
- pas de Selbrume ;
- pas de baseline screenshot.

## 15. Impact exports

Commande :

```bash
rg -n "projected_shadow_value_object_json_codecs|project_building_shadow_preset_json_codec|project_building_shadow_preset_catalog_json_codec|project_element_projected_building_shadow_config_json_codec|projected_building_shadow" packages/map_core/lib/map_core.dart
```

Résultat :

```text
31:export 'src/models/projected_building_shadow.dart';
46:export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
47:export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
48:export 'src/operations/project_building_shadow_preset_json_codec.dart';
53:export 'src/operations/projected_shadow_value_object_json_codecs.dart';
```

Décision :

- Les exports actuels sont suffisants.
- Le prochain lot n'a pas besoin d'ajouter un export public spécifique pour l'intégration.
- `project_manifest.dart` devra importer les modèles et codecs nécessaires en interne.

## 16. Diagnostics futurs

Diagnostics à planifier après l'intégration de persistance :

- élément avec `projectedBuildingShadow.presetId` absent du catalogue manifest ;
- catalogue vide mais éléments référencent des presets ;
- preset jamais utilisé ;
- élément avec `shadow` V1 et `projectedBuildingShadow` V2 ;
- `timeOfDayMode: followsSun` alors qu'aucun système jour/nuit n'est actif ;
- preset V2 valide mais rendu futur impossible faute d'asset/preview authoré.

Décision :

```text
Ne pas implémenter ces diagnostics dans le lot d'intégration initial si cela alourdit le diff.
```

Raison :

- le prochain lot doit seulement permettre de conserver les données V2 au round-trip ;
- les diagnostics méritent un lot dédié pour éviter de mélanger persistance, validation sémantique et UX.

## 17. Runtime / editor implications

Décision :

```text
L'intégration manifest/element sera persistence-only.
```

Elle ne devra pas :

- rendre les ombres V2 dans le runtime ;
- ajouter de preview ;
- ajouter d'UI éditeur ;
- créer de default presets ;
- convertir `genericProjection` V1 en V2 ;
- modifier Selbrume ;
- modifier les baselines screenshot.

Le runtime et l'éditeur devront ignorer ces nouvelles données tant que les lots dédiés ne les consomment pas.

## 18. Commandes lancées

Commandes exécutées pendant ce design gate :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "factory ProjectManifest|surfaceCatalog|shadowCatalog|ProjectManifest\.fromJson|ProjectManifest\(" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart packages/map_core/test/project_manifest_surface_integration_test.dart packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
rg -n "class ProjectElementEntry|ProjectElementEntry\(|ProjectElementEntry\.fromJson|shadow:|containsPair\('shadow'|projectedBuildingShadow" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart
rg -n "ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|projectedBuildingShadowCatalog|projectedBuildingShadow|encodeProjectBuildingShadowPresetCatalog|decodeProjectBuildingShadowPresetCatalog|encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2 reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md reports/shadows/v2/shadow_v2_12_project_element_projected_building_shadow_config_json_codec.md
rg -n "projected_shadow_value_object_json_codecs|project_building_shadow_preset_json_codec|project_building_shadow_preset_catalog_json_codec|project_element_projected_building_shadow_config_json_codec|projected_building_shadow" packages/map_core/lib/map_core.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 19. Résultats

Résultat d'audit :

- Le lot est bien design-only.
- `ProjectManifest` et `ProjectElementEntry` sont des modèles Freezed.
- `ProjectElementEntry` est dans `project_manifest.dart`.
- Les codecs V2 requis existent déjà.
- Les exports V2 existent déjà dans `map_core.dart`.
- Les tests V2-3 caractérisent que les clés V2-like sont aujourd'hui acceptées puis supprimées par `toJson`.
- Les prochaines modifications devront mettre fin à cette suppression pour les deux vraies clés V2.

Résultat des vérifications Git avant création du rapport :

- `git diff --stat` : aucune ligne.
- `git diff --name-status` : aucune ligne.
- `git diff --check` : aucune ligne.

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text

```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

```text
?? reports/shadows/v2/shadow_v2_13_projected_building_shadow_manifest_element_integration_design.md
```

## 24. Risques / réserves

- `includeIfNull: false` avec un `toJson` de champ non-nullable qui retourne `null` doit être validé par un test rouge/vert dans le prochain lot.
- `ProjectBuildingShadowPresetCatalog` n'a pas encore de constructeur vide const ; le prochain lot devra probablement l'ajouter pour un default Freezed propre.
- L'omission du root vide diverge volontairement du comportement V1 `shadowCatalog` et `surfaceCatalog`, qui émettent un catalogue vide. Cette divergence est assumée par ShadowV2-8 pour éviter le bruit V2 dans les anciens projets.
- L'ajout des champs Freezed modifiera des fichiers générés ; le prochain lot devra contenir une preuve claire que le churn est limité à `project_manifest.freezed.dart` et `project_manifest.g.dart`.
- Les diagnostics sémantiques des références `presetId` ne doivent pas être confondus avec la persistance JSON initiale.

## 25. Auto-critique

Le point le plus fragile est la frontière entre "absence root -> catalogue vide" et "root vide -> omis au toJson". Elle est correcte pour la compatibilité, mais elle exige des tests explicites parce qu'elle ne suit pas le comportement V1 `shadowCatalog`.

La seconde vigilance concerne Freezed : le design est simple côté domaine, mais l'implémentation générera mécaniquement du diff. Le prochain prompt doit forcer une vérification stricte des fichiers touchés.

## 26. Regard critique sur le prompt

Le prompt est bien borné : il interdit l'implémentation et demande les décisions nécessaires avant une opération sensible sur `project.json`.

Deux points à clarifier pour le prochain lot :

- autoriser explicitement `dart run build_runner build --delete-conflicting-outputs` dans `packages/map_core`, car l'intégration à `ProjectManifest` / `ProjectElementEntry` passera par Freezed ;
- autoriser explicitement la modification des fichiers générés `project_manifest.freezed.dart` et `project_manifest.g.dart`, en interdisant tout autre generated churn.

## 27. Prompt proposé pour le prochain lot

```md
# ShadowV2-14 — Projected Building Shadow Manifest / Element Persistence Integration V0

Tu travailles dans le repo local :

```text
/Users/karim/Project/pokemonProject
```

## Contrat

Implémenter uniquement l'intégration persistence JSON de ShadowV2 dans `map_core` :

- ajouter `ProjectManifest.projectedBuildingShadowCatalog` ;
- ajouter `ProjectElementEntry.projectedBuildingShadow` ;
- préserver les données V2 au round-trip ;
- ne pas modifier runtime/editor/Selbrume/screenshots ;
- ne pas créer de presets par défaut ;
- ne pas modifier les migrations pour injecter V2 ;
- ne pas faire de commit.

## Fichiers autorisés

- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart`
- fixtures JSON sous `packages/map_core/test/fixtures/shadow_v2/` si nécessaires
- rapport `reports/shadows/v2/shadow_v2_14_projected_building_shadow_manifest_element_persistence_integration.md`

## Décisions à appliquer

Manifest :

- champ Dart : `ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog`
- JSON root : `projectedBuildingShadowCatalog`
- absent -> catalogue vide
- null -> catalogue vide
- objet -> `decodeProjectBuildingShadowPresetCatalog`
- objet incomplet `{}` -> erreur
- catalogue vide -> omis par `toJson`
- catalogue non vide -> émis par `toJson`

Element :

- champ Dart : `ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow`
- JSON field : `projectedBuildingShadow`
- absent -> null
- null -> null
- objet -> `decodeProjectElementProjectedBuildingShadowConfig`
- null -> omis par `toJson`
- non-null -> émis par `toJson`
- V1 `shadow` et V2 `projectedBuildingShadow` peuvent coexister explicitement.

Migration :

- ne pas modifier `project_json_migrations.dart` pour injecter V2 ;
- aucun ancien projet ne gagne de V2 automatiquement.

## Tests requis

- manifest sans V2 decode catalogue vide et toJson omet root ;
- manifest avec root null decode catalogue vide et toJson omet root ;
- manifest avec `{ "presets": [] }` decode catalogue vide et toJson omet root ;
- manifest avec catalogue non vide round-trip et émet root ;
- manifest avec `{}` rejeté ;
- élément sans V2 decode null et toJson omet champ ;
- élément avec V2 null decode null et toJson omet champ ;
- élément avec V2 object round-trip ;
- élément avec V1 shadow + V2 projectedBuildingShadow round-trip les deux ;
- V2 keys ne sont plus supprimées au round-trip ;
- autres unknown keys conservent le comportement caractérisé.

## Commandes attendues

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
cd packages/map_core && dart test test/shadow_v2
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
cd packages/map_core && dart analyze lib/src/models/project_manifest.dart test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
cd /Users/karim/Project/pokemonProject
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Ne pas toucher au runtime, à l'éditeur, aux migrations injectives, à Selbrume ni aux baselines.
```

## 28. Evidence Pack

### git status initial

```text

```

### Résultat rg ProjectManifest

```text
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:12:        final manifest = ProjectManifest.fromJson(
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:69:      'unknown root future catalog keys are accepted by ProjectManifest.fromJson '
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:82:        final manifest = ProjectManifest.fromJson(raw);
packages/map_core/test/project_manifest_surface_integration_test.dart:24:    test('3. fromJson accepts missing surfaceCatalog key', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:40:    test('4. fromJson accepts surfaceCatalog: null as empty', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:64:    test('6. fromJson rejects incomplete surfaceCatalog (missing presets)', () {
packages/map_core/test/project_manifest_surface_integration_test.dart:147:    test('12. copyWith preserves surfaceCatalog when renaming', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:8:    test('decodes legacy manifest JSON without shadowCatalog as empty', () {
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:57:      expect(json['shadowCatalog'], <String, Object?>{
packages/map_core/test/shadow/project_manifest_shadow_catalog_json_test.dart:62:    test('copyWith replaces shadowCatalog', () {
packages/map_core/lib/src/models/project_manifest.dart:90:  factory ProjectManifest({
packages/map_core/lib/src/models/project_manifest.dart:128:      name: 'surfaceCatalog',
packages/map_core/lib/src/models/project_manifest.dart:132:    required ProjectSurfaceCatalog surfaceCatalog,
packages/map_core/lib/src/models/project_manifest.dart:135:    ProjectShadowCatalog shadowCatalog,
packages/map_core/lib/src/models/project_manifest.dart:138:  factory ProjectManifest.fromJson(Map<String, dynamic> json) =>
```

### Résultat rg ProjectElementEntry

```text
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:100:            'projectedBuildingShadow': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:107:        final element = ProjectElementEntry.fromJson(raw);
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:110:        expect(raw, contains('projectedBuildingShadow'));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:111:        expect(json, isNot(contains('projectedBuildingShadow')));
packages/map_core/lib/src/models/project_manifest.dart:368:class ProjectElementEntry with _$ProjectElementEntry {
packages/map_core/lib/src/models/project_manifest.dart:370:  const factory ProjectElementEntry({
packages/map_core/lib/src/models/project_manifest.dart:389:  factory ProjectElementEntry.fromJson(Map<String, dynamic> json) =>
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:9:      final element = ProjectElementEntry.fromJson(_elementJson());
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:15:      final element = ProjectElementEntry.fromJson(
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:74:      expect(json, containsPair('shadow', null));
packages/map_core/test/shadow/project_element_entry_shadow_json_test.dart:82:      final updated = _element().copyWith(shadow: shadow);
```

### Résultat rg V2 fields/models/codecs

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:291:final class ProjectBuildingShadowPresetCatalog {
packages/map_core/lib/src/models/projected_building_shadow.dart:292:  ProjectBuildingShadowPresetCatalog({
packages/map_core/lib/src/models/projected_building_shadow.dart:372:final class ProjectElementProjectedBuildingShadowConfig {
packages/map_core/lib/src/models/projected_building_shadow.dart:373:  factory ProjectElementProjectedBuildingShadowConfig({
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:38:Map<String, dynamic> encodeProjectBuildingShadowPresetCatalog(
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart:54:ProjectBuildingShadowPresetCatalog decodeProjectBuildingShadowPresetCatalog(
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:62:Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:78:ProjectElementProjectedBuildingShadowConfig
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:76:            'projectedBuildingShadowCatalog': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:88:        expect(json, isNot(contains('projectedBuildingShadowCatalog')));
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:100:            'projectedBuildingShadow': <String, Object?>{
packages/map_core/test/shadow_v2/projected_building_shadow_json_characterization_test.dart:111:        expect(json, isNot(contains('projectedBuildingShadow')));
reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md:140:| Nom du champ root catalogue | `projectedBuildingShadowCatalog` |
reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md:142:| Nom du champ élément | `projectedBuildingShadow` |
reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md:276:absence de projectedBuildingShadowCatalog -> ProjectBuildingShadowPresetCatalog vide
reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md:286:toJson omet projectedBuildingShadowCatalog si le catalogue est vide
reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md:305:absence de projectedBuildingShadow -> null en mémoire
reports/shadows/v2/shadow_v2_8_projected_building_shadow_json_design_compatibility_gate.md:315:decode "projectedBuildingShadow": null comme null ;
```

### Décision manifest

```text
Field Dart : ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog
JSON root : projectedBuildingShadowCatalog
Absent : catalogue vide
Null : catalogue vide
Empty : catalogue vide en mémoire, root omis au toJson
Non-empty : root émis via encodeProjectBuildingShadowPresetCatalog
```

### Décision element

```text
Field Dart : ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow
JSON field : projectedBuildingShadow
Absent : null
Null : null
Object : decodeProjectElementProjectedBuildingShadowConfig
toJson null : champ omis
V1+V2 : coexistence autorisée si explicitement authorée
```

### Décision migration

```text
Aucune injection V2 dans migrateProjectManifestJson.
L'absence est gérée par fromJson.
```

### Décision lot split

```text
Option A : lot unique ShadowV2-14 pour ProjectManifest + ProjectElementEntry.
```

## 29. Inventaire des fichiers

Créés :

- `reports/shadows/v2/shadow_v2_13_projected_building_shadow_manifest_element_integration_design.md`

Modifiés :

- Aucun fichier de code.
- Aucun test.
- Aucun modèle.
- Aucun codec.
- Aucune migration.
- Aucun fichier Selbrume.

Supprimés :

- Aucun.

Fichiers générés :

- Aucun.

Fichiers encore untracked liés au lot :

- `reports/shadows/v2/shadow_v2_13_projected_building_shadow_manifest_element_integration_design.md`

## 30. Prochain lot recommandé

```text
ShadowV2-14 — Projected Building Shadow Manifest / Element Persistence Integration V0
```

Objectif :

```text
Intégrer `projectedBuildingShadowCatalog` dans ProjectManifest et `projectedBuildingShadow` dans ProjectElementEntry, persistence-only, avec tests JSON ciblés et génération Freezed contrôlée.
```
