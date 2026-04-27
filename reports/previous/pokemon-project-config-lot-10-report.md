# Pokemon Project Config Lot 10 Report

## 1. Resume executif

Ce lot 10 ajoute un bloc de configuration Pokemon minimal dans `project.json`.

Ce qui a ete fait :
- ajout d'un modele `ProjectPokemonConfig` dans le manifest projet ;
- ajout d'un champ `pokemon` dans `ProjectManifest` avec valeurs par defaut ;
- migration legacy minimale pour les anciens projets sans bloc `pokemon` ;
- tests cibles sur la creation, le chargement, le round-trip et la legerete du bloc ;
- regeneration `freezed/json_serializable` pour le manifest projet.

Ce qui n'a pas ete fait :
- aucune donnee Pokemon inline dans `project.json` ;
- aucune UI ;
- aucun provider ;
- aucun runtime ;
- aucun import externe ;
- aucun index ;
- aucune lecture de masse des donnees Pokemon depuis `project.json`.

## 2. Objectif exact du lot

Repondre a une seule question :

> Comment le projet sait-il ou se trouvent ses donnees Pokemon locales, sans les embarquer dans `project.json` ?

La reponse retenue est une petite config de references explicites dans le manifest projet.

## 3. Perimetre inclus / exclu

### Inclus

- bloc `pokemon` dans `ProjectManifest` ;
- defaults coherents avec l'arborescence locale Pokemon deja retenue ;
- migration des anciens projets sans bloc `pokemon` ;
- compatibilite `loadProject` / `saveProject` / `CreateProjectUseCase` ;
- tests cibles ;
- analyse ciblee.

### Exclu

- aucune donnee Pokemon detaillee inline dans `project.json` ;
- aucune verification d'existence des fichiers Pokemon au chargement du projet ;
- aucune lecture de `data/pokemon/...` ;
- aucun use case Pokedex supplementaire ;
- aucune validation metier Pokemon lourde ;
- aucune UI ;
- aucun runtime ;
- aucun import externe.

## 4. Decisions d'architecture

### 4.1 Bloc Pokemon leger dans le manifest projet

Le manifest projet recoit maintenant un champ :

- `pokemon: ProjectPokemonConfig`

Ce bloc reste purement declaratif. Il ne contient que :
- `enabled`
- `dataRoot`
- `speciesDir`
- `learnsetsDir`
- `evolutionsDir`
- `mediaDir`
- `catalogFiles`

### 4.2 Valeurs par defaut

Les defaults retenus sont :

- `enabled: true`
- `dataRoot: data/pokemon`
- `speciesDir: data/pokemon/species`
- `learnsetsDir: data/pokemon/learnsets`
- `evolutionsDir: data/pokemon/evolutions`
- `mediaDir: data/pokemon/sprite_sets`
- `catalogFiles.moves: data/pokemon/catalogs/moves.json`
- `catalogFiles.abilities: data/pokemon/catalogs/abilities.json`
- `catalogFiles.items: data/pokemon/catalogs/items.json`
- `catalogFiles.types: data/pokemon/catalogs/types.json`
- `catalogFiles.growth_rates: data/pokemon/catalogs/growth_rates.json`
- `catalogFiles.natures: data/pokemon/catalogs/natures.json`

Note importante :
- le champ s'appelle `mediaDir` pour rester une config generique et legere ;
- la valeur par defaut pointe vers `data/pokemon/sprite_sets`, car c'est la convention reellement retenue aujourd'hui dans le projet.

### 4.3 Migration legacy minimale

La migration `migrateProjectManifestJson(...)` ajoute seulement un objet vide `pokemon` quand le bloc est absent.

Ensuite, la deserialisation applique les defaults du modele.

Cela permet :
- de charger les anciens projets sans erreur ;
- de garder une logique simple ;
- d'eviter une migration JSON verbeuse ou speculative.

### 4.4 Ajustement d'analyse minimal

`packages/map_core/analysis_options.yaml` a ete ajuste pour ignorer `invalid_annotation_target`.

Raison :
- `freezed` + `json_serializable` dans `map_core` remontaient des warnings d'annotations qui polluaient l'analyse ciblee ;
- ce n'est pas une extension de perimetre produit ;
- c'est un ajustement d'outillage minimal pour garder l'analyse propre sur le package modifie.

## 5. Structure exacte retenue pour le bloc Pokemon dans project.json

Exemple exact de structure retenue :

```json
{
  "pokemon": {
    "enabled": true,
    "dataRoot": "data/pokemon",
    "speciesDir": "data/pokemon/species",
    "learnsetsDir": "data/pokemon/learnsets",
    "evolutionsDir": "data/pokemon/evolutions",
    "mediaDir": "data/pokemon/sprite_sets",
    "catalogFiles": {
      "moves": "data/pokemon/catalogs/moves.json",
      "abilities": "data/pokemon/catalogs/abilities.json",
      "items": "data/pokemon/catalogs/items.json",
      "types": "data/pokemon/catalogs/types.json",
      "growth_rates": "data/pokemon/catalogs/growth_rates.json",
      "natures": "data/pokemon/catalogs/natures.json"
    }
  }
}
```

## 6. Preuve que project.json reste leger

Le test `creates a new project with the default lightweight pokemon config` verifie explicitement que le bloc `pokemon` ne contient que les cles de references :

- `enabled`
- `dataRoot`
- `speciesDir`
- `learnsetsDir`
- `evolutionsDir`
- `mediaDir`
- `catalogFiles`

Et qu'il ne contient pas de donnees metier inline du type :
- `species`
- `learnsets`
- `evolutions`
- `entries`

## 7. Fichiers crees / modifies

Modifies :
- `packages/map_core/analysis_options.yaml`
- `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.freezed.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart`

Crees :
- `packages/map_editor/test/project_pokemon_config_test.dart`
- `reports/pokemon-project-config-lot-10-report.md`

## 8. Tests reellement executes

### 8.1 map_core

Commande :

```bash
dart test test/legacy_editor_json_compat_collision_test.dart
```

Resultat reel :

```text
00:00 +0: legacy collision profile compat migrates broken manual house profile from full padding base to authored silhouette
00:00 +1: legacy collision profile compat migrates broken manual house profile from full padding base to authored silhouette
00:00 +1: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:00 +2: legacy collision profile compat unknown legacy keys do not prevent manifest parsing
00:00 +2: All tests passed!
```

### 8.2 map_editor

Commande :

```bash
flutter test test/project_pokemon_config_test.dart
```

Resultat reel :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/project_pokemon_config_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/project_pokemon_config_test.dart
00:01 +0: Project pokemon config loads an older project without pokemon config and applies defaults
00:01 +0: Project pokemon config loads an older project without pokemon config and applies defaults
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_s7mLfN/project.json
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_s7mLfN/project.json
00:01 +1: Project pokemon config loads an older project without pokemon config and applies defaults
00:01 +1: Project pokemon config creates a new project with the default lightweight pokemon config
00:01 +1: Project pokemon config creates a new project with the default lightweight pokemon config
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_accnuN/project.json
00:01 +2: Project pokemon config creates a new project with the default lightweight pokemon config
00:01 +2: Project pokemon config round-trips pokemon config through save and load without corruption
00:01 +2: Project pokemon config round-trips pokemon config through save and load without corruption
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_PTiD1E/project.json
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_PTiD1E/project.json
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_PTiD1E/project.json
00:01 +3: Project pokemon config round-trips pokemon config through save and load without corruption
00:01 +3: Project pokemon config loads project config without reading pokemon data files
00:01 +3: Project pokemon config loads project config without reading pokemon data files
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_BfcWpc/project.json
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_BfcWpc/project.json
00:01 +4: Project pokemon config loads project config without reading pokemon data files
00:01 +4: Project pokemon config does not recreate data or assets at the monorepo root
00:01 +4: Project pokemon config does not recreate data or assets at the monorepo root
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_ZhjYL9/project.json
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/project_pokemon_ZhjYL9/project.json
00:01 +5: Project pokemon config does not recreate data or assets at the monorepo root
00:01 +5: All tests passed!
```

## 9. Analyse reellement executee

### 9.1 map_core

Commande :

```bash
dart analyze lib/src/models/project_manifest.dart lib/src/io/legacy_editor_json_compat.dart test/legacy_editor_json_compat_collision_test.dart
```

Resultat reel :

```text
Analyzing project_manifest.dart, legacy_editor_json_compat.dart, legacy_editor_json_compat_collision_test.dart...
No issues found!
```

### 9.2 map_editor

Commande :

```bash
flutter analyze --no-pub test/project_pokemon_config_test.dart
```

Resultat reel :

```text
No issues found! (ran in 1.3s)
```

## 10. Verifications de perimetre

### 10.1 Aucun chargement des donnees Pokemon detaillees

Le test `loads project config without reading pokemon data files` prouve que le projet se charge correctement alors que :
- `data/pokemon` n'existe pas dans le workspace ;
- `assets/pokemon` n'existe pas dans le workspace.

Le lot 10 n'essaie donc pas de lire les donnees Pokemon detaillees au chargement du manifest projet.

### 10.2 Rien cree a la racine du monorepo

Commande :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie :

```text
```

Conclusion :
- aucun `./data`
- aucun `./assets`

n'ont ete crees a la racine du monorepo.

## 11. Etat Git utile

### 11.1 git status --short

```text
 M packages/map_core/analysis_options.yaml
 M packages/map_core/lib/src/io/legacy_editor_json_compat.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
?? packages/map_editor/test/project_pokemon_config_test.dart
?? reports/pokemon-project-config-lot-10-report.md
```

### 11.2 git diff --stat cible

Commande :

```bash
git diff --stat -- \
  packages/map_core/analysis_options.yaml \
  packages/map_core/lib/src/io/legacy_editor_json_compat.dart \
  packages/map_core/lib/src/models/project_manifest.dart \
  packages/map_core/lib/src/models/project_manifest.freezed.dart \
  packages/map_core/lib/src/models/project_manifest.g.dart \
  packages/map_editor/test/project_pokemon_config_test.dart \
  reports/pokemon-project-config-lot-10-report.md
```

Sortie :

```text
 packages/map_core/analysis_options.yaml            |   4 +
 .../lib/src/io/legacy_editor_json_compat.dart      |   3 +
 .../map_core/lib/src/models/project_manifest.dart  |  27 ++
 .../lib/src/models/project_manifest.freezed.dart   | 341 ++++++++++++++++++++-
 .../lib/src/models/project_manifest.g.dart         |  33 ++
 5 files changed, 407 insertions(+), 1 deletion(-)
```

Note honnete :
- `git diff --stat` ne montre pas le fichier de test et le rapport quand ils sont non suivis ;
- c'est pourquoi `git ls-files --others --exclude-standard` est ajoute ci-dessous.

### 11.3 git ls-files --others --exclude-standard

Commande :

```bash
git ls-files --others --exclude-standard \
  packages/map_editor/test/project_pokemon_config_test.dart \
  reports/pokemon-project-config-lot-10-report.md
```

Sortie :

```text
packages/map_editor/test/project_pokemon_config_test.dart
reports/pokemon-project-config-lot-10-report.md
```

## 12. Bundle de review

Commande executee :

```bash
./review_bundle.sh
```

Chemin du bundle genere :

```text
.review/review-20260409-221323.txt
```

Contenu integral du bundle :

```text
# REVIEW BUNDLE

Generated at: 2026-04-09 22:13:23
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: ed6ceb11b63f970058aa6c998c57993df87a5a3f

## GIT STATUS --SHORT

 M packages/map_core/analysis_options.yaml
 M packages/map_core/lib/src/io/legacy_editor_json_compat.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
?? packages/map_editor/test/project_pokemon_config_test.dart
?? reports/pokemon-project-config-lot-10-report.md

## GIT DIFF --STAT

 packages/map_core/analysis_options.yaml            |   4 +
 .../lib/src/io/legacy_editor_json_compat.dart      |   3 +
 .../map_core/lib/src/models/project_manifest.dart  |  27 ++
 .../lib/src/models/project_manifest.freezed.dart   | 341 ++++++++++++++++++++-
 .../lib/src/models/project_manifest.g.dart         |  33 ++
 5 files changed, 407 insertions(+), 1 deletion(-)

## CHANGED FILES

packages/map_core/analysis_options.yaml
packages/map_core/lib/src/io/legacy_editor_json_compat.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart

## RECENT COMMITS

ed6ceb1 LOT 9: Introduce `PokemonProjectValidator` for comprehensive Pokémon project validation
318a544 LOT 8: Add `PokemonWriteRepository` with integration tests for local Pokémon data saving
ff4a928 LOT 7: Introduce `PokemonReadRepository` abstraction and add tests
b4e651b LOT 6: Add Pokedex list use case and application model for minimal UI projection
c700532 LOT 5: Add Pokémon data models and reader service for structured JSON operations
f808d3f Seed Pokémon demo data use case with idempotent JSON generation
c4d2983 Enrich Pokémon JSON storage contract with manifest and minimal catalog structures
e266743 Add use case to initialize Pokémon project storage structure
c41fe7e Add data and assets folder structure with .gitkeep placeholders for future Pokémon content
3d81349 Add tests to confirm grid-based collision granularity limitations and document runtime constraints
8675f74 Add migration for broken legacy manual collision profiles
59dce2a Audit runtime collision logic to validate `cells` as the active source of truth
2aa52f4 Fix collision base model to support authored shapes and resolve padding-based overcapture issues
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor
fe5da3e Add tests for project collision profile persistence and enhance UI behavior in element collision editor

## FULL DIFF

diff --git a/packages/map_core/analysis_options.yaml b/packages/map_core/analysis_options.yaml
index dee8927..4a17c4d 100644
--- a/packages/map_core/analysis_options.yaml
+++ b/packages/map_core/analysis_options.yaml
@@ -13,6 +13,10 @@
 
 include: package:lints/recommended.yaml
 
+analyzer:
+  errors:
+    invalid_annotation_target: ignore
+
 # Uncomment the following section to specify additional rules.
 
 # linter:
diff --git a/packages/map_core/lib/src/io/legacy_editor_json_compat.dart b/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
index 3adfdd6..0b2933d 100644
--- a/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
+++ b/packages/map_core/lib/src/io/legacy_editor_json_compat.dart
@@ -12,6 +12,9 @@ Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
   if (!next.containsKey('characters')) {
     next['characters'] = <dynamic>[];
   }
+  if (!next.containsKey('pokemon')) {
+    next['pokemon'] = <String, dynamic>{};
+  }
   final settings = raw['settings'];
   if (settings is Map) {
     final migratedSettings =
diff --git a/packages/map_core/lib/src/models/project_manifest.dart b/packages/map_core/lib/src/models/project_manifest.dart
index 04ae9e0..7bb770d 100644
--- a/packages/map_core/lib/src/models/project_manifest.dart
+++ b/packages/map_core/lib/src/models/project_manifest.dart
@@ -13,6 +13,15 @@ Object? _readDefaultPlayerCharacterId(Map json, String _) {
   return json['defaultPlayerCharacterId'] ?? json['playerCharacterId'];
 }
 
+const Map<String, String> _defaultPokemonCatalogFiles = <String, String>{
+  'moves': 'data/pokemon/catalogs/moves.json',
+  'abilities': 'data/pokemon/catalogs/abilities.json',
+  'items': 'data/pokemon/catalogs/items.json',
+  'types': 'data/pokemon/catalogs/types.json',
+  'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
+  'natures': 'data/pokemon/catalogs/natures.json',
+};
+
 @freezed
 class ProjectManifest with _$ProjectManifest {
   @JsonSerializable(explicitToJson: true)
@@ -37,6 +46,7 @@ class ProjectManifest with _$ProjectManifest {
     @Default([]) List<ProjectTrainerEntry> trainers,
     @Default([]) List<ProjectCharacterEntry> characters,
     @Default(ProjectSettings()) ProjectSettings settings,
+    @Default(ProjectPokemonConfig()) ProjectPokemonConfig pokemon,
     @Default({}) Map<String, dynamic> globalProperties,
   }) = _ProjectManifest;
 
@@ -44,6 +54,23 @@ class ProjectManifest with _$ProjectManifest {
       _$ProjectManifestFromJson(json);
 }
 
+@freezed
+class ProjectPokemonConfig with _$ProjectPokemonConfig {
+  @JsonSerializable(explicitToJson: true)
+  const factory ProjectPokemonConfig({
+    @Default(true) bool enabled,
+    @Default('data/pokemon') String dataRoot,
+    @Default('data/pokemon/species') String speciesDir,
+    @Default('data/pokemon/learnsets') String learnsetsDir,
+    @Default('data/pokemon/evolutions') String evolutionsDir,
+    @Default('data/pokemon/sprite_sets') String mediaDir,
+    @Default(_defaultPokemonCatalogFiles) Map<String, String> catalogFiles,
+  }) = _ProjectPokemonConfig;
+
+  factory ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =>
+      _$ProjectPokemonConfigFromJson(json);
+}
+
 @freezed
 class ProjectSettings with _$ProjectSettings {
   @JsonSerializable(explicitToJson: true)
diff --git a/packages/map_core/lib/src/models/project_manifest.freezed.dart b/packages/map_core/lib/src/models/project_manifest.freezed.dart
index 4f95385..b9b57fa 100644
--- a/packages/map_core/lib/src/models/project_manifest.freezed.dart
+++ b/packages/map_core/lib/src/models/project_manifest.freezed.dart
@@ -49,6 +49,7 @@ mixin _$ProjectManifest {
   List<ProjectCharacterEntry> get characters =>
       throw _privateConstructorUsedError;
   ProjectSettings get settings => throw _privateConstructorUsedError;
+  ProjectPokemonConfig get pokemon => throw _privateConstructorUsedError;
   Map<String, dynamic> get globalProperties =>
       throw _privateConstructorUsedError;
 
@@ -89,9 +90,11 @@ abstract class $ProjectManifestCopyWith<$Res> {
       List<ProjectTrainerEntry> trainers,
       List<ProjectCharacterEntry> characters,
       ProjectSettings settings,
+      ProjectPokemonConfig pokemon,
       Map<String, dynamic> globalProperties});
 
   $ProjectSettingsCopyWith<$Res> get settings;
+  $ProjectPokemonConfigCopyWith<$Res> get pokemon;
 }
 
 /// @nodoc
@@ -129,6 +132,7 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
     Object? trainers = null,
     Object? characters = null,
     Object? settings = null,
+    Object? pokemon = null,
     Object? globalProperties = null,
   }) {
     return _then(_value.copyWith(
@@ -212,6 +216,10 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
           ? _value.settings
           : settings // ignore: cast_nullable_to_non_nullable
               as ProjectSettings,
+      pokemon: null == pokemon
+          ? _value.pokemon
+          : pokemon // ignore: cast_nullable_to_non_nullable
+              as ProjectPokemonConfig,
       globalProperties: null == globalProperties
           ? _value.globalProperties
           : globalProperties // ignore: cast_nullable_to_non_nullable
@@ -228,6 +236,16 @@ class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
       return _then(_value.copyWith(settings: value) as $Val);
     });
   }
+
+  /// Create a copy of ProjectManifest
+  /// with the given fields replaced by the non-null parameter values.
+  @override
+  @pragma('vm:prefer-inline')
+  $ProjectPokemonConfigCopyWith<$Res> get pokemon {
+    return $ProjectPokemonConfigCopyWith<$Res>(_value.pokemon, (value) {
+      return _then(_value.copyWith(pokemon: value) as $Val);
+    });
+  }
 }
 
 /// @nodoc
@@ -259,10 +277,13 @@ abstract class _$$ProjectManifestImplCopyWith<$Res>
       List<ProjectTrainerEntry> trainers,
       List<ProjectCharacterEntry> characters,
       ProjectSettings settings,
+      ProjectPokemonConfig pokemon,
       Map<String, dynamic> globalProperties});
 
   @override
   $ProjectSettingsCopyWith<$Res> get settings;
+  @override
+  $ProjectPokemonConfigCopyWith<$Res> get pokemon;
 }
 
 /// @nodoc
@@ -298,6 +319,7 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
     Object? trainers = null,
     Object? characters = null,
     Object? settings = null,
+    Object? pokemon = null,
     Object? globalProperties = null,
   }) {
     return _then(_$ProjectManifestImpl(
@@ -381,6 +403,10 @@ class __$$ProjectManifestImplCopyWithImpl<$Res>
           ? _value.settings
           : settings // ignore: cast_nullable_to_non_nullable
               as ProjectSettings,
+      pokemon: null == pokemon
+          ? _value.pokemon
+          : pokemon // ignore: cast_nullable_to_non_nullable
+              as ProjectPokemonConfig,
       globalProperties: null == globalProperties
           ? _value._globalProperties
           : globalProperties // ignore: cast_nullable_to_non_nullable
@@ -414,6 +440,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
       final List<ProjectTrainerEntry> trainers = const [],
       final List<ProjectCharacterEntry> characters = const [],
       this.settings = const ProjectSettings(),
+      this.pokemon = const ProjectPokemonConfig(),
       final Map<String, dynamic> globalProperties = const {}})
       : _maps = maps,
         _groups = groups,
@@ -598,6 +625,9 @@ class _$ProjectManifestImpl implements _ProjectManifest {
   @override
   @JsonKey()
   final ProjectSettings settings;
+  @override
+  @JsonKey()
+  final ProjectPokemonConfig pokemon;
   final Map<String, dynamic> _globalProperties;
   @override
   @JsonKey()
@@ -609,7 +639,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
 
   @override
   String toString() {
-    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, globalProperties: $globalProperties)';
+    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties)';
   }
 
   @override
@@ -649,6 +679,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
                 .equals(other._characters, _characters) &&
             (identical(other.settings, settings) ||
                 other.settings == settings) &&
+            (identical(other.pokemon, pokemon) || other.pokemon == pokemon) &&
             const DeepCollectionEquality()
                 .equals(other._globalProperties, _globalProperties));
   }
@@ -677,6 +708,7 @@ class _$ProjectManifestImpl implements _ProjectManifest {
         const DeepCollectionEquality().hash(_trainers),
         const DeepCollectionEquality().hash(_characters),
         settings,
+        pokemon,
         const DeepCollectionEquality().hash(_globalProperties)
       ]);
 
@@ -719,6 +751,7 @@ abstract class _ProjectManifest implements ProjectManifest {
       final List<ProjectTrainerEntry> trainers,
       final List<ProjectCharacterEntry> characters,
       final ProjectSettings settings,
+      final ProjectPokemonConfig pokemon,
       final Map<String, dynamic> globalProperties}) = _$ProjectManifestImpl;
 
   factory _ProjectManifest.fromJson(Map<String, dynamic> json) =
@@ -765,6 +798,8 @@ abstract class _ProjectManifest implements ProjectManifest {
   @override
   ProjectSettings get settings;
   @override
+  ProjectPokemonConfig get pokemon;
+  @override
   Map<String, dynamic> get globalProperties;
 
   /// Create a copy of ProjectManifest
@@ -775,6 +810,310 @@ abstract class _ProjectManifest implements ProjectManifest {
       throw _privateConstructorUsedError;
 }
 
+ProjectPokemonConfig _$ProjectPokemonConfigFromJson(Map<String, dynamic> json) {
+  return _ProjectPokemonConfig.fromJson(json);
+}
+
+/// @nodoc
+mixin _$ProjectPokemonConfig {
+  bool get enabled => throw _privateConstructorUsedError;
+  String get dataRoot => throw _privateConstructorUsedError;
+  String get speciesDir => throw _privateConstructorUsedError;
+  String get learnsetsDir => throw _privateConstructorUsedError;
+  String get evolutionsDir => throw _privateConstructorUsedError;
+  String get mediaDir => throw _privateConstructorUsedError;
+  Map<String, String> get catalogFiles => throw _privateConstructorUsedError;
+
+  /// Serializes this ProjectPokemonConfig to a JSON map.
+  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
+
+  /// Create a copy of ProjectPokemonConfig
+  /// with the given fields replaced by the non-null parameter values.
+  @JsonKey(includeFromJson: false, includeToJson: false)
+  $ProjectPokemonConfigCopyWith<ProjectPokemonConfig> get copyWith =>
+      throw _privateConstructorUsedError;
+}
+
+/// @nodoc
+abstract class $ProjectPokemonConfigCopyWith<$Res> {
+  factory $ProjectPokemonConfigCopyWith(ProjectPokemonConfig value,
+          $Res Function(ProjectPokemonConfig) then) =
+      _$ProjectPokemonConfigCopyWithImpl<$Res, ProjectPokemonConfig>;
+  @useResult
+  $Res call(
+      {bool enabled,
+      String dataRoot,
+      String speciesDir,
+      String learnsetsDir,
+      String evolutionsDir,
+      String mediaDir,
+      Map<String, String> catalogFiles});
+}
+
+/// @nodoc
+class _$ProjectPokemonConfigCopyWithImpl<$Res,
+        $Val extends ProjectPokemonConfig>
+    implements $ProjectPokemonConfigCopyWith<$Res> {
+  _$ProjectPokemonConfigCopyWithImpl(this._value, this._then);
+
+  // ignore: unused_field
+  final $Val _value;
+  // ignore: unused_field
+  final $Res Function($Val) _then;
+
+  /// Create a copy of ProjectPokemonConfig
+  /// with the given fields replaced by the non-null parameter values.
+  @pragma('vm:prefer-inline')
+  @override
+  $Res call({
+    Object? enabled = null,
+    Object? dataRoot = null,
+    Object? speciesDir = null,
+    Object? learnsetsDir = null,
+    Object? evolutionsDir = null,
+    Object? mediaDir = null,
+    Object? catalogFiles = null,
+  }) {
+    return _then(_value.copyWith(
+      enabled: null == enabled
+          ? _value.enabled
+          : enabled // ignore: cast_nullable_to_non_nullable
+              as bool,
+      dataRoot: null == dataRoot
+          ? _value.dataRoot
+          : dataRoot // ignore: cast_nullable_to_non_nullable
+              as String,
+      speciesDir: null == speciesDir
+          ? _value.speciesDir
+          : speciesDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      learnsetsDir: null == learnsetsDir
+          ? _value.learnsetsDir
+          : learnsetsDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      evolutionsDir: null == evolutionsDir
+          ? _value.evolutionsDir
+          : evolutionsDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      mediaDir: null == mediaDir
+          ? _value.mediaDir
+          : mediaDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      catalogFiles: null == catalogFiles
+          ? _value.catalogFiles
+          : catalogFiles // ignore: cast_nullable_to_non_nullable
+              as Map<String, String>,
+    ) as $Val);
+  }
+}
+
+/// @nodoc
+abstract class _$$ProjectPokemonConfigImplCopyWith<$Res>
+    implements $ProjectPokemonConfigCopyWith<$Res> {
+  factory _$$ProjectPokemonConfigImplCopyWith(_$ProjectPokemonConfigImpl value,
+          $Res Function(_$ProjectPokemonConfigImpl) then) =
+      __$$ProjectPokemonConfigImplCopyWithImpl<$Res>;
+  @override
+  @useResult
+  $Res call(
+      {bool enabled,
+      String dataRoot,
+      String speciesDir,
+      String learnsetsDir,
+      String evolutionsDir,
+      String mediaDir,
+      Map<String, String> catalogFiles});
+}
+
+/// @nodoc
+class __$$ProjectPokemonConfigImplCopyWithImpl<$Res>
+    extends _$ProjectPokemonConfigCopyWithImpl<$Res, _$ProjectPokemonConfigImpl>
+    implements _$$ProjectPokemonConfigImplCopyWith<$Res> {
+  __$$ProjectPokemonConfigImplCopyWithImpl(_$ProjectPokemonConfigImpl _value,
+      $Res Function(_$ProjectPokemonConfigImpl) _then)
+      : super(_value, _then);
+
+  /// Create a copy of ProjectPokemonConfig
+  /// with the given fields replaced by the non-null parameter values.
+  @pragma('vm:prefer-inline')
+  @override
+  $Res call({
+    Object? enabled = null,
+    Object? dataRoot = null,
+    Object? speciesDir = null,
+    Object? learnsetsDir = null,
+    Object? evolutionsDir = null,
+    Object? mediaDir = null,
+    Object? catalogFiles = null,
+  }) {
+    return _then(_$ProjectPokemonConfigImpl(
+      enabled: null == enabled
+          ? _value.enabled
+          : enabled // ignore: cast_nullable_to_non_nullable
+              as bool,
+      dataRoot: null == dataRoot
+          ? _value.dataRoot
+          : dataRoot // ignore: cast_nullable_to_non_nullable
+              as String,
+      speciesDir: null == speciesDir
+          ? _value.speciesDir
+          : speciesDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      learnsetsDir: null == learnsetsDir
+          ? _value.learnsetsDir
+          : learnsetsDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      evolutionsDir: null == evolutionsDir
+          ? _value.evolutionsDir
+          : evolutionsDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      mediaDir: null == mediaDir
+          ? _value.mediaDir
+          : mediaDir // ignore: cast_nullable_to_non_nullable
+              as String,
+      catalogFiles: null == catalogFiles
+          ? _value._catalogFiles
+          : catalogFiles // ignore: cast_nullable_to_non_nullable
+              as Map<String, String>,
+    ));
+  }
+}
+
+/// @nodoc
+
+@JsonSerializable(explicitToJson: true)
+class _$ProjectPokemonConfigImpl implements _ProjectPokemonConfig {
+  const _$ProjectPokemonConfigImpl(
+      {this.enabled = true,
+      this.dataRoot = 'data/pokemon',
+      this.speciesDir = 'data/pokemon/species',
+      this.learnsetsDir = 'data/pokemon/learnsets',
+      this.evolutionsDir = 'data/pokemon/evolutions',
+      this.mediaDir = 'data/pokemon/sprite_sets',
+      final Map<String, String> catalogFiles = _defaultPokemonCatalogFiles})
+      : _catalogFiles = catalogFiles;
+
+  factory _$ProjectPokemonConfigImpl.fromJson(Map<String, dynamic> json) =>
+      _$$ProjectPokemonConfigImplFromJson(json);
+
+  @override
+  @JsonKey()
+  final bool enabled;
+  @override
+  @JsonKey()
+  final String dataRoot;
+  @override
+  @JsonKey()
+  final String speciesDir;
+  @override
+  @JsonKey()
+  final String learnsetsDir;
+  @override
+  @JsonKey()
+  final String evolutionsDir;
+  @override
+  @JsonKey()
+  final String mediaDir;
+  final Map<String, String> _catalogFiles;
+  @override
+  @JsonKey()
+  Map<String, String> get catalogFiles {
+    if (_catalogFiles is EqualUnmodifiableMapView) return _catalogFiles;
+    // ignore: implicit_dynamic_type
+    return EqualUnmodifiableMapView(_catalogFiles);
+  }
+
+  @override
+  String toString() {
+    return 'ProjectPokemonConfig(enabled: $enabled, dataRoot: $dataRoot, speciesDir: $speciesDir, learnsetsDir: $learnsetsDir, evolutionsDir: $evolutionsDir, mediaDir: $mediaDir, catalogFiles: $catalogFiles)';
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        (other.runtimeType == runtimeType &&
+            other is _$ProjectPokemonConfigImpl &&
+            (identical(other.enabled, enabled) || other.enabled == enabled) &&
+            (identical(other.dataRoot, dataRoot) ||
+                other.dataRoot == dataRoot) &&
+            (identical(other.speciesDir, speciesDir) ||
+                other.speciesDir == speciesDir) &&
+            (identical(other.learnsetsDir, learnsetsDir) ||
+                other.learnsetsDir == learnsetsDir) &&
+            (identical(other.evolutionsDir, evolutionsDir) ||
+                other.evolutionsDir == evolutionsDir) &&
+            (identical(other.mediaDir, mediaDir) ||
+                other.mediaDir == mediaDir) &&
+            const DeepCollectionEquality()
+                .equals(other._catalogFiles, _catalogFiles));
+  }
+
+  @JsonKey(includeFromJson: false, includeToJson: false)
+  @override
+  int get hashCode => Object.hash(
+      runtimeType,
+      enabled,
+      dataRoot,
+      speciesDir,
+      learnsetsDir,
+      evolutionsDir,
+      mediaDir,
+      const DeepCollectionEquality().hash(_catalogFiles));
+
+  /// Create a copy of ProjectPokemonConfig
+  /// with the given fields replaced by the non-null parameter values.
+  @JsonKey(includeFromJson: false, includeToJson: false)
+  @override
+  @pragma('vm:prefer-inline')
+  _$$ProjectPokemonConfigImplCopyWith<_$ProjectPokemonConfigImpl>
+      get copyWith =>
+          __$$ProjectPokemonConfigImplCopyWithImpl<_$ProjectPokemonConfigImpl>(
+              this, _$identity);
+
+  @override
+  Map<String, dynamic> toJson() {
+    return _$$ProjectPokemonConfigImplToJson(
+      this,
+    );
+  }
+}
+
+abstract class _ProjectPokemonConfig implements ProjectPokemonConfig {
+  const factory _ProjectPokemonConfig(
+      {final bool enabled,
+      final String dataRoot,
+      final String speciesDir,
+      final String learnsetsDir,
+      final String evolutionsDir,
+      final String mediaDir,
+      final Map<String, String> catalogFiles}) = _$ProjectPokemonConfigImpl;
+
+  factory _ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =
+      _$ProjectPokemonConfigImpl.fromJson;
+
+  @override
+  bool get enabled;
+  @override
+  String get dataRoot;
+  @override
+  String get speciesDir;
+  @override
+  String get learnsetsDir;
+  @override
+  String get evolutionsDir;
+  @override
+  String get mediaDir;
+  @override
+  Map<String, String> get catalogFiles;
+
+  /// Create a copy of ProjectPokemonConfig
+  /// with the given fields replaced by the non-null parameter values.
+  @override
+  @JsonKey(includeFromJson: false, includeToJson: false)
+  _$$ProjectPokemonConfigImplCopyWith<_$ProjectPokemonConfigImpl>
+      get copyWith => throw _privateConstructorUsedError;
+}
+
 ProjectSettings _$ProjectSettingsFromJson(Map<String, dynamic> json) {
   return _ProjectSettings.fromJson(json);
 }
diff --git a/packages/map_core/lib/src/models/project_manifest.g.dart b/packages/map_core/lib/src/models/project_manifest.g.dart
index 5455204..66cb5cf 100644
--- a/packages/map_core/lib/src/models/project_manifest.g.dart
+++ b/packages/map_core/lib/src/models/project_manifest.g.dart
@@ -94,6 +94,10 @@ _$ProjectManifestImpl _$$ProjectManifestImplFromJson(
       settings: json['settings'] == null
           ? const ProjectSettings()
           : ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
+      pokemon: json['pokemon'] == null
+          ? const ProjectPokemonConfig()
+          : ProjectPokemonConfig.fromJson(
+              json['pokemon'] as Map<String, dynamic>),
       globalProperties:
           json['globalProperties'] as Map<String, dynamic>? ?? const {},
     );
@@ -125,6 +129,7 @@ Map<String, dynamic> _$$ProjectManifestImplToJson(
       'trainers': instance.trainers.map((e) => e.toJson()).toList(),
       'characters': instance.characters.map((e) => e.toJson()).toList(),
       'settings': instance.settings.toJson(),
+      'pokemon': instance.pokemon.toJson(),
       'globalProperties': instance.globalProperties,
     };
 
@@ -132,6 +137,34 @@ const _$ProjectVersionEnumMap = {
   ProjectVersion.v1: 'v1',
 };
 
+_$ProjectPokemonConfigImpl _$$ProjectPokemonConfigImplFromJson(
+        Map<String, dynamic> json) =>
+    _$ProjectPokemonConfigImpl(
+      enabled: json['enabled'] as bool? ?? true,
+      dataRoot: json['dataRoot'] as String? ?? 'data/pokemon',
+      speciesDir: json['speciesDir'] as String? ?? 'data/pokemon/species',
+      learnsetsDir: json['learnsetsDir'] as String? ?? 'data/pokemon/learnsets',
+      evolutionsDir:
+          json['evolutionsDir'] as String? ?? 'data/pokemon/evolutions',
+      mediaDir: json['mediaDir'] as String? ?? 'data/pokemon/sprite_sets',
+      catalogFiles: (json['catalogFiles'] as Map<String, dynamic>?)?.map(
+            (k, e) => MapEntry(k, e as String),
+          ) ??
+          _defaultPokemonCatalogFiles,
+    );
+
+Map<String, dynamic> _$$ProjectPokemonConfigImplToJson(
+        _$ProjectPokemonConfigImpl instance) =>
+    <String, dynamic>{
+      'enabled': instance.enabled,
+      'dataRoot': instance.dataRoot,
+      'speciesDir': instance.speciesDir,
+      'learnsetsDir': instance.learnsetsDir,
+      'evolutionsDir': instance.evolutionsDir,
+      'mediaDir': instance.mediaDir,
+      'catalogFiles': instance.catalogFiles,
+    };
+
 _$ProjectSettingsImpl _$$ProjectSettingsImplFromJson(
         Map<String, dynamic> json) =>
     _$ProjectSettingsImpl(

```

## 13. Code integral de tous les fichiers crees ou modifies

### 13.1 packages/map_core/analysis_options.yaml

```yaml
# This file configures the static analysis results for your project (errors,
# warnings, and lints).
#
# This enables the 'recommended' set of lints from `package:lints`.
# This set helps identify many issues that may lead to problems when running
# or consuming Dart code, and enforces writing Dart using a single, idiomatic
# style and format.
#
# If you want a smaller set of lints you can change this to specify
# 'package:lints/core.yaml'. These are just the most critical lints
# (the recommended set includes the core lints).
# The core lints are also what is used by pub.dev for scoring packages.

include: package:lints/recommended.yaml

analyzer:
  errors:
    invalid_annotation_target: ignore

# Uncomment the following section to specify additional rules.

# linter:
#   rules:
#     - camel_case_types

# analyzer:
#   exclude:
#     - path/to/excluded/files/**

# For more information about the core and recommended set of lints, see
# https://dart.dev/go/core-lints

# For additional information about configuring this file, see
# https://dart.dev/guides/language/analysis-options
```

### 13.2 packages/map_core/lib/src/io/legacy_editor_json_compat.dart

```dart
Map<String, dynamic> migrateProjectManifestJson(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);
  if (!next.containsKey('dialogues')) {
    next['dialogues'] = <dynamic>[];
  }
  if (!next.containsKey('dialogueFolders')) {
    next['dialogueFolders'] = <dynamic>[];
  }
  if (!next.containsKey('tilesetFolders')) {
    next['tilesetFolders'] = <dynamic>[];
  }
  if (!next.containsKey('characters')) {
    next['characters'] = <dynamic>[];
  }
  if (!next.containsKey('pokemon')) {
    next['pokemon'] = <String, dynamic>{};
  }
  final settings = raw['settings'];
  if (settings is Map) {
    final migratedSettings =
        Map<String, dynamic>.from(settings.cast<String, dynamic>());
    if (!migratedSettings.containsKey('defaultPlayerCharacterId') &&
        migratedSettings['playerCharacterId'] != null) {
      migratedSettings['defaultPlayerCharacterId'] =
          migratedSettings['playerCharacterId'];
    }
    next['settings'] = migratedSettings;
  }
  final legacyCategories = raw['terrainPresetCategories'];
  if (!next.containsKey('terrainCategories') && legacyCategories is List) {
    next['terrainCategories'] = legacyCategories
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .where((entry) => entry['kind'] == 'terrain')
        .map((entry) {
      entry.remove('kind');
      return entry;
    }).toList(growable: false);
  }
  if (!next.containsKey('pathCategories') && legacyCategories is List) {
    next['pathCategories'] = legacyCategories
        .whereType<Map>()
        .map(
            (entry) => Map<String, dynamic>.from(entry.cast<String, dynamic>()))
        .where((entry) => entry['kind'] == 'path')
        .map((entry) {
      entry.remove('kind');
      return entry;
    }).toList(growable: false);
  }

  final pathPresets = raw['pathPresets'];
  if (pathPresets is! List) {
    final trainers = raw['trainers'];
    if (trainers is List) {
      next['trainers'] = trainers.map((entry) {
        if (entry is! Map) {
          return entry;
        }
        final trainer =
            Map<String, dynamic>.from(entry.cast<String, dynamic>());
        if (!trainer.containsKey('characterId')) {
          final legacyCharacterId = trainer['overworldCharacterId'] ??
              trainer['spriteCharacterId'] ??
              trainer['characterRef'];
          if (legacyCharacterId != null) {
            trainer['characterId'] = legacyCharacterId;
          }
        }
        return trainer;
      }).toList(growable: false);
    }
    _migrateElementCollisionProfiles(next);
    return next;
  }

  next['pathPresets'] = pathPresets.map((entry) {
    if (entry is! Map) {
      return entry;
    }
    final preset = Map<String, dynamic>.from(entry.cast<String, dynamic>());
    if (!preset.containsKey('surfaceKind')) {
      preset['surfaceKind'] = _legacyPathSurfaceKindValue(
        preset['groundTerrainType']?.toString(),
      );
    }
    return preset;
  }).toList(growable: false);

  final trainers = raw['trainers'];
  if (trainers is List) {
    next['trainers'] = trainers.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final trainer = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      if (!trainer.containsKey('characterId')) {
        final legacyCharacterId = trainer['overworldCharacterId'] ??
            trainer['spriteCharacterId'] ??
            trainer['characterRef'];
        if (legacyCharacterId != null) {
          trainer['characterId'] = legacyCharacterId;
        }
      }
      return trainer;
    }).toList(growable: false);
  }

  _migrateElementCollisionProfiles(next);

  return next;
}

void _migrateElementCollisionProfiles(Map<String, dynamic> manifest) {
  // Collision profile compatibility:
  //
  // Older editor builds could save a "manual" building silhouette in a broken
  // shape:
  // - `source == manual`
  // - `padding == 0`
  // - `cells == full padding-derived rectangle`
  // - `manualAddedCells == intended building silhouette`
  //
  // The modern editor preview can reinterpret that payload in memory, but the
  // runtime only reads `collisionProfile.cells`. If we do not normalize the
  // manifest at load time, the runtime keeps blocking the full sprite bounds.
  //
  // We therefore repair only the proven legacy pattern here, at manifest-load
  // time, so editor, save/reload, and runtime all agree on the same final
  // `cells` without introducing a new runtime contract.
  final rawElements = manifest['elements'];
  if (rawElements is! List) {
    return;
  }

  final settings = manifest['settings'];
  final tileWidth =
      settings is Map ? (_asInt(settings['tileWidth']) ?? 16) : 16;
  final tileHeight =
      settings is Map ? (_asInt(settings['tileHeight']) ?? 16) : 16;

  manifest['elements'] = rawElements.map((entry) {
    if (entry is! Map) {
      return entry;
    }
    final element = Map<String, dynamic>.from(entry.cast<String, dynamic>());
    final rawProfile = element['collisionProfile'];
    if (rawProfile is! Map) {
      return element;
    }

    final sourceSize = _readElementSourceSize(element);
    if (sourceSize == null) {
      return element;
    }

    element['collisionProfile'] = _migrateCollisionProfileJson(
      rawProfile.cast<String, dynamic>(),
      sourceWidth: sourceSize.$1,
      sourceHeight: sourceSize.$2,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
    );
    return element;
  }).toList(growable: false);
}

Map<String, dynamic> _migrateCollisionProfileJson(
  Map<String, dynamic> rawProfile, {
  required int sourceWidth,
  required int sourceHeight,
  required int tileWidth,
  required int tileHeight,
}) {
  final profile = Map<String, dynamic>.from(rawProfile);
  final sourceMode = profile['source']?.toString() ?? 'generated';
  final padding = _readPadding(profile['padding']);
  final currentCells = _normalizeCells(
    profile['cells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final shapeCells = _normalizeCells(
    profile['shapeCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final manualAddedCells = _normalizeCells(
    profile['manualAddedCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final manualRemovedCells = _normalizeCells(
    profile['manualRemovedCells'],
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
  );
  final paddingBaseCells = _deriveBaseCellsFromPadding(
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    padding: padding,
  );

  if (sourceMode == 'manual') {
    // Legacy broken payload:
    // `cells` persisted the full padding-derived base while the intended house
    // silhouette lived only in `manualAddedCells`. This is the exact failure
    // mode observed on the real `petite_maison_toit_bleu` project file.
    if (shapeCells.isEmpty &&
        manualAddedCells.isNotEmpty &&
        manualRemovedCells.isEmpty &&
        _sameCells(currentCells, paddingBaseCells)) {
      profile['shapeCells'] = _toJsonCells(manualAddedCells);
      profile['manualAddedCells'] = const <Map<String, dynamic>>[];
      profile['manualRemovedCells'] = const <Map<String, dynamic>>[];
      profile['cells'] = _toJsonCells(manualAddedCells);
      return profile;
    }

    // Older manual profiles may have stored the intended authored silhouette
    // directly in `cells` without `shapeCells`. Preserve that intent so future
    // saves stop bouncing back to a generated rectangle.
    if (shapeCells.isEmpty &&
        manualAddedCells.isEmpty &&
        manualRemovedCells.isEmpty &&
        currentCells.isNotEmpty &&
        !_sameCells(currentCells, paddingBaseCells)) {
      profile['shapeCells'] = _toJsonCells(currentCells);
      profile['cells'] = _toJsonCells(currentCells);
      return profile;
    }

    if (shapeCells.isNotEmpty) {
      final finalCells = _applyOverlay(
        baseCells: shapeCells,
        manualAddedCells: manualAddedCells,
        manualRemovedCells: manualRemovedCells,
      );
      profile['shapeCells'] = _toJsonCells(shapeCells);
      profile['manualAddedCells'] = _toJsonCells(manualAddedCells);
      profile['manualRemovedCells'] = _toJsonCells(manualRemovedCells);
      profile['cells'] = _toJsonCells(finalCells);
      return profile;
    }
  }

  // For generated profiles, keep the modern contract deterministic: `cells`
  // should reflect the padding base plus explicit overrides. This keeps runtime
  // truth aligned with the data the editor will display after reload.
  final generatedFinalCells = _applyOverlay(
    baseCells: paddingBaseCells,
    manualAddedCells: manualAddedCells,
    manualRemovedCells: manualRemovedCells,
  );
  profile['shapeCells'] = _toJsonCells(shapeCells);
  profile['manualAddedCells'] = _toJsonCells(manualAddedCells);
  profile['manualRemovedCells'] = _toJsonCells(manualRemovedCells);
  profile['cells'] = _toJsonCells(generatedFinalCells);
  return profile;
}

({int top, int right, int bottom, int left}) _readPadding(Object? rawPadding) {
  if (rawPadding is! Map) {
    return (top: 0, right: 0, bottom: 0, left: 0);
  }
  return (
    top: _asInt(rawPadding['top']) ?? 0,
    right: _asInt(rawPadding['right']) ?? 0,
    bottom: _asInt(rawPadding['bottom']) ?? 0,
    left: _asInt(rawPadding['left']) ?? 0,
  );
}

(int, int)? _readElementSourceSize(Map<String, dynamic> element) {
  final frames = element['frames'];
  if (frames is List && frames.isNotEmpty) {
    final first = frames.first;
    if (first is Map) {
      final source = first['source'];
      if (source is Map) {
        final width = _asInt(source['width']);
        final height = _asInt(source['height']);
        if (width != null && height != null && width > 0 && height > 0) {
          return (width, height);
        }
      }
    }
  }

  final legacySource = element['source'];
  if (legacySource is Map) {
    final width = _asInt(legacySource['width']);
    final height = _asInt(legacySource['height']);
    if (width != null && height != null && width > 0 && height > 0) {
      return (width, height);
    }
  }
  return null;
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

List<Map<String, dynamic>> _toJsonCells(List<(int, int)> cells) {
  return cells
      .map((cell) => <String, dynamic>{'x': cell.$1, 'y': cell.$2})
      .toList(growable: false);
}

List<(int, int)> _normalizeCells(
  Object? rawCells, {
  required int sourceWidth,
  required int sourceHeight,
}) {
  if (rawCells is! List) {
    return const <(int, int)>[];
  }
  final unique = <String, (int, int)>{};
  for (final cell in rawCells) {
    if (cell is! Map) {
      continue;
    }
    final x = _asInt(cell['x']);
    final y = _asInt(cell['y']);
    if (x == null || y == null) {
      continue;
    }
    if (x < 0 || y < 0 || x >= sourceWidth || y >= sourceHeight) {
      continue;
    }
    unique['$x:$y'] = (x, y);
  }
  final out = unique.values.toList(growable: false);
  out.sort(_compareCells);
  return out;
}

List<(int, int)> _deriveBaseCellsFromPadding({
  required int sourceWidth,
  required int sourceHeight,
  required int tileWidth,
  required int tileHeight,
  required ({int top, int right, int bottom, int left}) padding,
}) {
  if (sourceWidth <= 0 ||
      sourceHeight <= 0 ||
      tileWidth <= 0 ||
      tileHeight <= 0) {
    return const <(int, int)>[];
  }

  final sourcePixelWidth = sourceWidth * tileWidth;
  final sourcePixelHeight = sourceHeight * tileHeight;
  final trimmedLeft = padding.left.clamp(0, sourcePixelWidth);
  final trimmedTop = padding.top.clamp(0, sourcePixelHeight);
  final trimmedRight =
      (sourcePixelWidth - padding.right.clamp(0, sourcePixelWidth))
          .clamp(trimmedLeft, sourcePixelWidth);
  final trimmedBottom =
      (sourcePixelHeight - padding.bottom.clamp(0, sourcePixelHeight))
          .clamp(trimmedTop, sourcePixelHeight);

  if (trimmedRight <= trimmedLeft || trimmedBottom <= trimmedTop) {
    return const <(int, int)>[];
  }

  final out = <(int, int)>[];
  for (var y = 0; y < sourceHeight; y++) {
    final cellTop = y * tileHeight;
    final cellBottom = cellTop + tileHeight;
    final overlapsY = cellBottom > trimmedTop && cellTop < trimmedBottom;
    if (!overlapsY) {
      continue;
    }
    for (var x = 0; x < sourceWidth; x++) {
      final cellLeft = x * tileWidth;
      final cellRight = cellLeft + tileWidth;
      final overlapsX = cellRight > trimmedLeft && cellLeft < trimmedRight;
      if (!overlapsX) {
        continue;
      }
      out.add((x, y));
    }
  }
  return out;
}

List<(int, int)> _applyOverlay({
  required List<(int, int)> baseCells,
  required List<(int, int)> manualAddedCells,
  required List<(int, int)> manualRemovedCells,
}) {
  final merged = <String, (int, int)>{
    for (final cell in baseCells) '${cell.$1}:${cell.$2}': cell,
  };
  for (final cell in manualAddedCells) {
    merged['${cell.$1}:${cell.$2}'] = cell;
  }
  for (final cell in manualRemovedCells) {
    merged.remove('${cell.$1}:${cell.$2}');
  }
  final out = merged.values.toList(growable: false);
  out.sort(_compareCells);
  return out;
}

bool _sameCells(List<(int, int)> a, List<(int, int)> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

int _compareCells((int, int) a, (int, int) b) {
  final yCompare = a.$2.compareTo(b.$2);
  if (yCompare != 0) {
    return yCompare;
  }
  return a.$1.compareTo(b.$1);
}

String _legacyPathSurfaceKindValue(String? legacyValue) {
  return switch (legacyValue) {
    'water' => 'water',
    'ice' => 'ice',
    'lava' => 'lava',
    'mud' => 'swamp',
    'tallGrass' => 'tall_grass',
    'road' => 'road',
    'rails' => 'rails',
    'bridge' => 'bridge',
    'custom' => 'custom',
    _ => 'path',
  };
}

Map<String, dynamic> migrateMapDataJson(Map<String, dynamic> raw) {
  final next = Map<String, dynamic>.from(raw);
  final entities = raw['entities'];
  if (entities is List) {
    next['entities'] = entities.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final entity = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      final rawKind = entity['kind']?.toString();
      final rawType = entity['type']?.toString();
      entity['kind'] = _legacyEntityKindValue(rawKind ?? rawType);
      entity.remove('type');
      entity['name'] = (entity['name'] ?? entity['id'] ?? '').toString();

      if (!entity.containsKey('size')) {
        entity['size'] = <String, dynamic>{
          'width': 1,
          'height': 1,
        };
      }

      final rawProperties = entity['properties'];
      if (rawProperties is Map) {
        entity['properties'] = {
          for (final property in rawProperties.entries)
            property.key.toString(): property.value?.toString() ?? '',
        };
      } else {
        entity['properties'] = <String, String>{};
      }

      return entity;
    }).toList(growable: false);
  }

  final triggers = raw['triggers'];
  if (triggers is List) {
    next['triggers'] = triggers.map((entry) {
      if (entry is! Map) {
        return entry;
      }
      final trigger = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      if (!trigger.containsKey('area') && trigger['zone'] is Map) {
        trigger['area'] = Map<String, dynamic>.from(
            (trigger['zone'] as Map).cast<String, dynamic>());
      }
      trigger['name'] = (trigger['name'] ?? trigger['id'] ?? '').toString();

      final rawType = trigger['type']?.toString();
      trigger['type'] = switch (rawType) {
        'script' => 'event',
        'cutscene' => 'event',
        'battle' => 'event',
        'sound' => 'interaction',
        'warp' => 'warp',
        'message' => 'message',
        'interaction' => 'interaction',
        'event' => 'event',
        'spawn' => 'spawn',
        'camera' => 'camera',
        'custom' => 'custom',
        _ => 'event',
      };

      final rawProperties = trigger['properties'];
      if (rawProperties is Map) {
        trigger['properties'] = {
          for (final entry in rawProperties.entries)
            entry.key.toString(): entry.value?.toString() ?? '',
        };
      } else {
        trigger['properties'] = <String, String>{};
      }
      return trigger;
    }).toList(growable: false);
  }

  final md = next['mapMetadata'];
  if (md == null || md is! Map) {
    next['mapMetadata'] = <String, dynamic>{};
  }
  if (!next.containsKey('placedElements') || next['placedElements'] == null) {
    next['placedElements'] = <dynamic>[];
  }

  return next;
}

String _legacyEntityKindValue(String? legacyValue) {
  return switch (legacyValue) {
    'npc' => 'npc',
    'monster' => 'npc',
    'sign' => 'sign',
    'chest' => 'item',
    'item' => 'item',
    'spawn' => 'spawn',
    'custom' => 'custom',
    _ => 'custom',
  };
}
```

### 13.3 packages/map_core/lib/src/models/project_manifest.dart

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'element_collision_profile.dart';
import 'enums.dart';
import 'project_trainer.dart';
import 'scenario_asset.dart';
import 'script_asset.dart';
import 'visual_frame_json.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

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
};

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectManifest({
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
    @Default('data/pokemon/sprite_sets') String mediaDir,
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

### 13.4 packages/map_core/lib/src/models/project_manifest.freezed.dart

```dart
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProjectManifest _$ProjectManifestFromJson(Map<String, dynamic> json) {
  return _ProjectManifest.fromJson(json);
}

/// @nodoc
mixin _$ProjectManifest {
  String get name => throw _privateConstructorUsedError;
  ProjectVersion get version => throw _privateConstructorUsedError;
  List<ProjectMapEntry> get maps => throw _privateConstructorUsedError;
  List<ProjectMapGroup> get groups => throw _privateConstructorUsedError;
  List<ProjectTilesetFolder> get tilesetFolders =>
      throw _privateConstructorUsedError;
  List<ProjectTilesetEntry> get tilesets => throw _privateConstructorUsedError;
  List<ProjectElementCategory> get elementCategories =>
      throw _privateConstructorUsedError;
  List<ProjectElementEntry> get elements => throw _privateConstructorUsedError;
  List<ProjectPresetCategory> get terrainCategories =>
      throw _privateConstructorUsedError;
  List<ProjectPresetCategory> get pathCategories =>
      throw _privateConstructorUsedError;
  List<ProjectTerrainPreset> get terrainPresets =>
      throw _privateConstructorUsedError;
  List<ProjectPathPreset> get pathPresets => throw _privateConstructorUsedError;
  List<ProjectEncounterTable> get encounterTables =>
      throw _privateConstructorUsedError;
  List<ProjectDialogueFolder> get dialogueFolders =>
      throw _privateConstructorUsedError;
  List<ProjectDialogueEntry> get dialogues =>
      throw _privateConstructorUsedError;
  List<ProjectScriptEntry> get scripts => throw _privateConstructorUsedError;
  List<ScenarioAsset> get scenarios => throw _privateConstructorUsedError;
  List<ProjectTrainerEntry> get trainers => throw _privateConstructorUsedError;
  List<ProjectCharacterEntry> get characters =>
      throw _privateConstructorUsedError;
  ProjectSettings get settings => throw _privateConstructorUsedError;
  ProjectPokemonConfig get pokemon => throw _privateConstructorUsedError;
  Map<String, dynamic> get globalProperties =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectManifest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectManifestCopyWith<ProjectManifest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectManifestCopyWith<$Res> {
  factory $ProjectManifestCopyWith(
          ProjectManifest value, $Res Function(ProjectManifest) then) =
      _$ProjectManifestCopyWithImpl<$Res, ProjectManifest>;
  @useResult
  $Res call(
      {String name,
      ProjectVersion version,
      List<ProjectMapEntry> maps,
      List<ProjectMapGroup> groups,
      List<ProjectTilesetFolder> tilesetFolders,
      List<ProjectTilesetEntry> tilesets,
      List<ProjectElementCategory> elementCategories,
      List<ProjectElementEntry> elements,
      List<ProjectPresetCategory> terrainCategories,
      List<ProjectPresetCategory> pathCategories,
      List<ProjectTerrainPreset> terrainPresets,
      List<ProjectPathPreset> pathPresets,
      List<ProjectEncounterTable> encounterTables,
      List<ProjectDialogueFolder> dialogueFolders,
      List<ProjectDialogueEntry> dialogues,
      List<ProjectScriptEntry> scripts,
      List<ScenarioAsset> scenarios,
      List<ProjectTrainerEntry> trainers,
      List<ProjectCharacterEntry> characters,
      ProjectSettings settings,
      ProjectPokemonConfig pokemon,
      Map<String, dynamic> globalProperties});

  $ProjectSettingsCopyWith<$Res> get settings;
  $ProjectPokemonConfigCopyWith<$Res> get pokemon;
}

/// @nodoc
class _$ProjectManifestCopyWithImpl<$Res, $Val extends ProjectManifest>
    implements $ProjectManifestCopyWith<$Res> {
  _$ProjectManifestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? version = null,
    Object? maps = null,
    Object? groups = null,
    Object? tilesetFolders = null,
    Object? tilesets = null,
    Object? elementCategories = null,
    Object? elements = null,
    Object? terrainCategories = null,
    Object? pathCategories = null,
    Object? terrainPresets = null,
    Object? pathPresets = null,
    Object? encounterTables = null,
    Object? dialogueFolders = null,
    Object? dialogues = null,
    Object? scripts = null,
    Object? scenarios = null,
    Object? trainers = null,
    Object? characters = null,
    Object? settings = null,
    Object? pokemon = null,
    Object? globalProperties = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as ProjectVersion,
      maps: null == maps
          ? _value.maps
          : maps // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapEntry>,
      groups: null == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapGroup>,
      tilesetFolders: null == tilesetFolders
          ? _value.tilesetFolders
          : tilesetFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetFolder>,
      tilesets: null == tilesets
          ? _value.tilesets
          : tilesets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetEntry>,
      elementCategories: null == elementCategories
          ? _value.elementCategories
          : elementCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementCategory>,
      elements: null == elements
          ? _value.elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementEntry>,
      terrainCategories: null == terrainCategories
          ? _value.terrainCategories
          : terrainCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      pathCategories: null == pathCategories
          ? _value.pathCategories
          : pathCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      terrainPresets: null == terrainPresets
          ? _value.terrainPresets
          : terrainPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTerrainPreset>,
      pathPresets: null == pathPresets
          ? _value.pathPresets
          : pathPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectPathPreset>,
      encounterTables: null == encounterTables
          ? _value.encounterTables
          : encounterTables // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterTable>,
      dialogueFolders: null == dialogueFolders
          ? _value.dialogueFolders
          : dialogueFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueFolder>,
      dialogues: null == dialogues
          ? _value.dialogues
          : dialogues // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueEntry>,
      scripts: null == scripts
          ? _value.scripts
          : scripts // ignore: cast_nullable_to_non_nullable
              as List<ProjectScriptEntry>,
      scenarios: null == scenarios
          ? _value.scenarios
          : scenarios // ignore: cast_nullable_to_non_nullable
              as List<ScenarioAsset>,
      trainers: null == trainers
          ? _value.trainers
          : trainers // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerEntry>,
      characters: null == characters
          ? _value.characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<ProjectCharacterEntry>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as ProjectSettings,
      pokemon: null == pokemon
          ? _value.pokemon
          : pokemon // ignore: cast_nullable_to_non_nullable
              as ProjectPokemonConfig,
      globalProperties: null == globalProperties
          ? _value.globalProperties
          : globalProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectSettingsCopyWith<$Res> get settings {
    return $ProjectSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectPokemonConfigCopyWith<$Res> get pokemon {
    return $ProjectPokemonConfigCopyWith<$Res>(_value.pokemon, (value) {
      return _then(_value.copyWith(pokemon: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectManifestImplCopyWith<$Res>
    implements $ProjectManifestCopyWith<$Res> {
  factory _$$ProjectManifestImplCopyWith(_$ProjectManifestImpl value,
          $Res Function(_$ProjectManifestImpl) then) =
      __$$ProjectManifestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      ProjectVersion version,
      List<ProjectMapEntry> maps,
      List<ProjectMapGroup> groups,
      List<ProjectTilesetFolder> tilesetFolders,
      List<ProjectTilesetEntry> tilesets,
      List<ProjectElementCategory> elementCategories,
      List<ProjectElementEntry> elements,
      List<ProjectPresetCategory> terrainCategories,
      List<ProjectPresetCategory> pathCategories,
      List<ProjectTerrainPreset> terrainPresets,
      List<ProjectPathPreset> pathPresets,
      List<ProjectEncounterTable> encounterTables,
      List<ProjectDialogueFolder> dialogueFolders,
      List<ProjectDialogueEntry> dialogues,
      List<ProjectScriptEntry> scripts,
      List<ScenarioAsset> scenarios,
      List<ProjectTrainerEntry> trainers,
      List<ProjectCharacterEntry> characters,
      ProjectSettings settings,
      ProjectPokemonConfig pokemon,
      Map<String, dynamic> globalProperties});

  @override
  $ProjectSettingsCopyWith<$Res> get settings;
  @override
  $ProjectPokemonConfigCopyWith<$Res> get pokemon;
}

/// @nodoc
class __$$ProjectManifestImplCopyWithImpl<$Res>
    extends _$ProjectManifestCopyWithImpl<$Res, _$ProjectManifestImpl>
    implements _$$ProjectManifestImplCopyWith<$Res> {
  __$$ProjectManifestImplCopyWithImpl(
      _$ProjectManifestImpl _value, $Res Function(_$ProjectManifestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? version = null,
    Object? maps = null,
    Object? groups = null,
    Object? tilesetFolders = null,
    Object? tilesets = null,
    Object? elementCategories = null,
    Object? elements = null,
    Object? terrainCategories = null,
    Object? pathCategories = null,
    Object? terrainPresets = null,
    Object? pathPresets = null,
    Object? encounterTables = null,
    Object? dialogueFolders = null,
    Object? dialogues = null,
    Object? scripts = null,
    Object? scenarios = null,
    Object? trainers = null,
    Object? characters = null,
    Object? settings = null,
    Object? pokemon = null,
    Object? globalProperties = null,
  }) {
    return _then(_$ProjectManifestImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as ProjectVersion,
      maps: null == maps
          ? _value._maps
          : maps // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapEntry>,
      groups: null == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<ProjectMapGroup>,
      tilesetFolders: null == tilesetFolders
          ? _value._tilesetFolders
          : tilesetFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetFolder>,
      tilesets: null == tilesets
          ? _value._tilesets
          : tilesets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTilesetEntry>,
      elementCategories: null == elementCategories
          ? _value._elementCategories
          : elementCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementCategory>,
      elements: null == elements
          ? _value._elements
          : elements // ignore: cast_nullable_to_non_nullable
              as List<ProjectElementEntry>,
      terrainCategories: null == terrainCategories
          ? _value._terrainCategories
          : terrainCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      pathCategories: null == pathCategories
          ? _value._pathCategories
          : pathCategories // ignore: cast_nullable_to_non_nullable
              as List<ProjectPresetCategory>,
      terrainPresets: null == terrainPresets
          ? _value._terrainPresets
          : terrainPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectTerrainPreset>,
      pathPresets: null == pathPresets
          ? _value._pathPresets
          : pathPresets // ignore: cast_nullable_to_non_nullable
              as List<ProjectPathPreset>,
      encounterTables: null == encounterTables
          ? _value._encounterTables
          : encounterTables // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterTable>,
      dialogueFolders: null == dialogueFolders
          ? _value._dialogueFolders
          : dialogueFolders // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueFolder>,
      dialogues: null == dialogues
          ? _value._dialogues
          : dialogues // ignore: cast_nullable_to_non_nullable
              as List<ProjectDialogueEntry>,
      scripts: null == scripts
          ? _value._scripts
          : scripts // ignore: cast_nullable_to_non_nullable
              as List<ProjectScriptEntry>,
      scenarios: null == scenarios
          ? _value._scenarios
          : scenarios // ignore: cast_nullable_to_non_nullable
              as List<ScenarioAsset>,
      trainers: null == trainers
          ? _value._trainers
          : trainers // ignore: cast_nullable_to_non_nullable
              as List<ProjectTrainerEntry>,
      characters: null == characters
          ? _value._characters
          : characters // ignore: cast_nullable_to_non_nullable
              as List<ProjectCharacterEntry>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as ProjectSettings,
      pokemon: null == pokemon
          ? _value.pokemon
          : pokemon // ignore: cast_nullable_to_non_nullable
              as ProjectPokemonConfig,
      globalProperties: null == globalProperties
          ? _value._globalProperties
          : globalProperties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectManifestImpl implements _ProjectManifest {
  const _$ProjectManifestImpl(
      {required this.name,
      this.version = ProjectVersion.v1,
      required final List<ProjectMapEntry> maps,
      final List<ProjectMapGroup> groups = const [],
      final List<ProjectTilesetFolder> tilesetFolders = const [],
      required final List<ProjectTilesetEntry> tilesets,
      final List<ProjectElementCategory> elementCategories = const [],
      final List<ProjectElementEntry> elements = const [],
      final List<ProjectPresetCategory> terrainCategories = const [],
      final List<ProjectPresetCategory> pathCategories = const [],
      final List<ProjectTerrainPreset> terrainPresets = const [],
      final List<ProjectPathPreset> pathPresets = const [],
      final List<ProjectEncounterTable> encounterTables = const [],
      final List<ProjectDialogueFolder> dialogueFolders = const [],
      final List<ProjectDialogueEntry> dialogues = const [],
      final List<ProjectScriptEntry> scripts = const [],
      final List<ScenarioAsset> scenarios = const [],
      final List<ProjectTrainerEntry> trainers = const [],
      final List<ProjectCharacterEntry> characters = const [],
      this.settings = const ProjectSettings(),
      this.pokemon = const ProjectPokemonConfig(),
      final Map<String, dynamic> globalProperties = const {}})
      : _maps = maps,
        _groups = groups,
        _tilesetFolders = tilesetFolders,
        _tilesets = tilesets,
        _elementCategories = elementCategories,
        _elements = elements,
        _terrainCategories = terrainCategories,
        _pathCategories = pathCategories,
        _terrainPresets = terrainPresets,
        _pathPresets = pathPresets,
        _encounterTables = encounterTables,
        _dialogueFolders = dialogueFolders,
        _dialogues = dialogues,
        _scripts = scripts,
        _scenarios = scenarios,
        _trainers = trainers,
        _characters = characters,
        _globalProperties = globalProperties;

  factory _$ProjectManifestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectManifestImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey()
  final ProjectVersion version;
  final List<ProjectMapEntry> _maps;
  @override
  List<ProjectMapEntry> get maps {
    if (_maps is EqualUnmodifiableListView) return _maps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_maps);
  }

  final List<ProjectMapGroup> _groups;
  @override
  @JsonKey()
  List<ProjectMapGroup> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  final List<ProjectTilesetFolder> _tilesetFolders;
  @override
  @JsonKey()
  List<ProjectTilesetFolder> get tilesetFolders {
    if (_tilesetFolders is EqualUnmodifiableListView) return _tilesetFolders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tilesetFolders);
  }

  final List<ProjectTilesetEntry> _tilesets;
  @override
  List<ProjectTilesetEntry> get tilesets {
    if (_tilesets is EqualUnmodifiableListView) return _tilesets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tilesets);
  }

  final List<ProjectElementCategory> _elementCategories;
  @override
  @JsonKey()
  List<ProjectElementCategory> get elementCategories {
    if (_elementCategories is EqualUnmodifiableListView)
      return _elementCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elementCategories);
  }

  final List<ProjectElementEntry> _elements;
  @override
  @JsonKey()
  List<ProjectElementEntry> get elements {
    if (_elements is EqualUnmodifiableListView) return _elements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elements);
  }

  final List<ProjectPresetCategory> _terrainCategories;
  @override
  @JsonKey()
  List<ProjectPresetCategory> get terrainCategories {
    if (_terrainCategories is EqualUnmodifiableListView)
      return _terrainCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_terrainCategories);
  }

  final List<ProjectPresetCategory> _pathCategories;
  @override
  @JsonKey()
  List<ProjectPresetCategory> get pathCategories {
    if (_pathCategories is EqualUnmodifiableListView) return _pathCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pathCategories);
  }

  final List<ProjectTerrainPreset> _terrainPresets;
  @override
  @JsonKey()
  List<ProjectTerrainPreset> get terrainPresets {
    if (_terrainPresets is EqualUnmodifiableListView) return _terrainPresets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_terrainPresets);
  }

  final List<ProjectPathPreset> _pathPresets;
  @override
  @JsonKey()
  List<ProjectPathPreset> get pathPresets {
    if (_pathPresets is EqualUnmodifiableListView) return _pathPresets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pathPresets);
  }

  final List<ProjectEncounterTable> _encounterTables;
  @override
  @JsonKey()
  List<ProjectEncounterTable> get encounterTables {
    if (_encounterTables is EqualUnmodifiableListView) return _encounterTables;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_encounterTables);
  }

  final List<ProjectDialogueFolder> _dialogueFolders;
  @override
  @JsonKey()
  List<ProjectDialogueFolder> get dialogueFolders {
    if (_dialogueFolders is EqualUnmodifiableListView) return _dialogueFolders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dialogueFolders);
  }

  final List<ProjectDialogueEntry> _dialogues;
  @override
  @JsonKey()
  List<ProjectDialogueEntry> get dialogues {
    if (_dialogues is EqualUnmodifiableListView) return _dialogues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dialogues);
  }

  final List<ProjectScriptEntry> _scripts;
  @override
  @JsonKey()
  List<ProjectScriptEntry> get scripts {
    if (_scripts is EqualUnmodifiableListView) return _scripts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scripts);
  }

  final List<ScenarioAsset> _scenarios;
  @override
  @JsonKey()
  List<ScenarioAsset> get scenarios {
    if (_scenarios is EqualUnmodifiableListView) return _scenarios;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scenarios);
  }

  final List<ProjectTrainerEntry> _trainers;
  @override
  @JsonKey()
  List<ProjectTrainerEntry> get trainers {
    if (_trainers is EqualUnmodifiableListView) return _trainers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_trainers);
  }

  final List<ProjectCharacterEntry> _characters;
  @override
  @JsonKey()
  List<ProjectCharacterEntry> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  @override
  @JsonKey()
  final ProjectSettings settings;
  @override
  @JsonKey()
  final ProjectPokemonConfig pokemon;
  final Map<String, dynamic> _globalProperties;
  @override
  @JsonKey()
  Map<String, dynamic> get globalProperties {
    if (_globalProperties is EqualUnmodifiableMapView) return _globalProperties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_globalProperties);
  }

  @override
  String toString() {
    return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, terrainCategories: $terrainCategories, pathCategories: $pathCategories, terrainPresets: $terrainPresets, pathPresets: $pathPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, trainers: $trainers, characters: $characters, settings: $settings, pokemon: $pokemon, globalProperties: $globalProperties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectManifestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other._maps, _maps) &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality()
                .equals(other._tilesetFolders, _tilesetFolders) &&
            const DeepCollectionEquality().equals(other._tilesets, _tilesets) &&
            const DeepCollectionEquality()
                .equals(other._elementCategories, _elementCategories) &&
            const DeepCollectionEquality().equals(other._elements, _elements) &&
            const DeepCollectionEquality()
                .equals(other._terrainCategories, _terrainCategories) &&
            const DeepCollectionEquality()
                .equals(other._pathCategories, _pathCategories) &&
            const DeepCollectionEquality()
                .equals(other._terrainPresets, _terrainPresets) &&
            const DeepCollectionEquality()
                .equals(other._pathPresets, _pathPresets) &&
            const DeepCollectionEquality()
                .equals(other._encounterTables, _encounterTables) &&
            const DeepCollectionEquality()
                .equals(other._dialogueFolders, _dialogueFolders) &&
            const DeepCollectionEquality()
                .equals(other._dialogues, _dialogues) &&
            const DeepCollectionEquality().equals(other._scripts, _scripts) &&
            const DeepCollectionEquality()
                .equals(other._scenarios, _scenarios) &&
            const DeepCollectionEquality().equals(other._trainers, _trainers) &&
            const DeepCollectionEquality()
                .equals(other._characters, _characters) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.pokemon, pokemon) || other.pokemon == pokemon) &&
            const DeepCollectionEquality()
                .equals(other._globalProperties, _globalProperties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        name,
        version,
        const DeepCollectionEquality().hash(_maps),
        const DeepCollectionEquality().hash(_groups),
        const DeepCollectionEquality().hash(_tilesetFolders),
        const DeepCollectionEquality().hash(_tilesets),
        const DeepCollectionEquality().hash(_elementCategories),
        const DeepCollectionEquality().hash(_elements),
        const DeepCollectionEquality().hash(_terrainCategories),
        const DeepCollectionEquality().hash(_pathCategories),
        const DeepCollectionEquality().hash(_terrainPresets),
        const DeepCollectionEquality().hash(_pathPresets),
        const DeepCollectionEquality().hash(_encounterTables),
        const DeepCollectionEquality().hash(_dialogueFolders),
        const DeepCollectionEquality().hash(_dialogues),
        const DeepCollectionEquality().hash(_scripts),
        const DeepCollectionEquality().hash(_scenarios),
        const DeepCollectionEquality().hash(_trainers),
        const DeepCollectionEquality().hash(_characters),
        settings,
        pokemon,
        const DeepCollectionEquality().hash(_globalProperties)
      ]);

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectManifestImplCopyWith<_$ProjectManifestImpl> get copyWith =>
      __$$ProjectManifestImplCopyWithImpl<_$ProjectManifestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectManifestImplToJson(
      this,
    );
  }
}

abstract class _ProjectManifest implements ProjectManifest {
  const factory _ProjectManifest(
      {required final String name,
      final ProjectVersion version,
      required final List<ProjectMapEntry> maps,
      final List<ProjectMapGroup> groups,
      final List<ProjectTilesetFolder> tilesetFolders,
      required final List<ProjectTilesetEntry> tilesets,
      final List<ProjectElementCategory> elementCategories,
      final List<ProjectElementEntry> elements,
      final List<ProjectPresetCategory> terrainCategories,
      final List<ProjectPresetCategory> pathCategories,
      final List<ProjectTerrainPreset> terrainPresets,
      final List<ProjectPathPreset> pathPresets,
      final List<ProjectEncounterTable> encounterTables,
      final List<ProjectDialogueFolder> dialogueFolders,
      final List<ProjectDialogueEntry> dialogues,
      final List<ProjectScriptEntry> scripts,
      final List<ScenarioAsset> scenarios,
      final List<ProjectTrainerEntry> trainers,
      final List<ProjectCharacterEntry> characters,
      final ProjectSettings settings,
      final ProjectPokemonConfig pokemon,
      final Map<String, dynamic> globalProperties}) = _$ProjectManifestImpl;

  factory _ProjectManifest.fromJson(Map<String, dynamic> json) =
      _$ProjectManifestImpl.fromJson;

  @override
  String get name;
  @override
  ProjectVersion get version;
  @override
  List<ProjectMapEntry> get maps;
  @override
  List<ProjectMapGroup> get groups;
  @override
  List<ProjectTilesetFolder> get tilesetFolders;
  @override
  List<ProjectTilesetEntry> get tilesets;
  @override
  List<ProjectElementCategory> get elementCategories;
  @override
  List<ProjectElementEntry> get elements;
  @override
  List<ProjectPresetCategory> get terrainCategories;
  @override
  List<ProjectPresetCategory> get pathCategories;
  @override
  List<ProjectTerrainPreset> get terrainPresets;
  @override
  List<ProjectPathPreset> get pathPresets;
  @override
  List<ProjectEncounterTable> get encounterTables;
  @override
  List<ProjectDialogueFolder> get dialogueFolders;
  @override
  List<ProjectDialogueEntry> get dialogues;
  @override
  List<ProjectScriptEntry> get scripts;
  @override
  List<ScenarioAsset> get scenarios;
  @override
  List<ProjectTrainerEntry> get trainers;
  @override
  List<ProjectCharacterEntry> get characters;
  @override
  ProjectSettings get settings;
  @override
  ProjectPokemonConfig get pokemon;
  @override
  Map<String, dynamic> get globalProperties;

  /// Create a copy of ProjectManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectManifestImplCopyWith<_$ProjectManifestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectPokemonConfig _$ProjectPokemonConfigFromJson(Map<String, dynamic> json) {
  return _ProjectPokemonConfig.fromJson(json);
}

/// @nodoc
mixin _$ProjectPokemonConfig {
  bool get enabled => throw _privateConstructorUsedError;
  String get dataRoot => throw _privateConstructorUsedError;
  String get speciesDir => throw _privateConstructorUsedError;
  String get learnsetsDir => throw _privateConstructorUsedError;
  String get evolutionsDir => throw _privateConstructorUsedError;
  String get mediaDir => throw _privateConstructorUsedError;
  Map<String, String> get catalogFiles => throw _privateConstructorUsedError;

  /// Serializes this ProjectPokemonConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPokemonConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPokemonConfigCopyWith<ProjectPokemonConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPokemonConfigCopyWith<$Res> {
  factory $ProjectPokemonConfigCopyWith(ProjectPokemonConfig value,
          $Res Function(ProjectPokemonConfig) then) =
      _$ProjectPokemonConfigCopyWithImpl<$Res, ProjectPokemonConfig>;
  @useResult
  $Res call(
      {bool enabled,
      String dataRoot,
      String speciesDir,
      String learnsetsDir,
      String evolutionsDir,
      String mediaDir,
      Map<String, String> catalogFiles});
}

/// @nodoc
class _$ProjectPokemonConfigCopyWithImpl<$Res,
        $Val extends ProjectPokemonConfig>
    implements $ProjectPokemonConfigCopyWith<$Res> {
  _$ProjectPokemonConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPokemonConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? dataRoot = null,
    Object? speciesDir = null,
    Object? learnsetsDir = null,
    Object? evolutionsDir = null,
    Object? mediaDir = null,
    Object? catalogFiles = null,
  }) {
    return _then(_value.copyWith(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      dataRoot: null == dataRoot
          ? _value.dataRoot
          : dataRoot // ignore: cast_nullable_to_non_nullable
              as String,
      speciesDir: null == speciesDir
          ? _value.speciesDir
          : speciesDir // ignore: cast_nullable_to_non_nullable
              as String,
      learnsetsDir: null == learnsetsDir
          ? _value.learnsetsDir
          : learnsetsDir // ignore: cast_nullable_to_non_nullable
              as String,
      evolutionsDir: null == evolutionsDir
          ? _value.evolutionsDir
          : evolutionsDir // ignore: cast_nullable_to_non_nullable
              as String,
      mediaDir: null == mediaDir
          ? _value.mediaDir
          : mediaDir // ignore: cast_nullable_to_non_nullable
              as String,
      catalogFiles: null == catalogFiles
          ? _value.catalogFiles
          : catalogFiles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectPokemonConfigImplCopyWith<$Res>
    implements $ProjectPokemonConfigCopyWith<$Res> {
  factory _$$ProjectPokemonConfigImplCopyWith(_$ProjectPokemonConfigImpl value,
          $Res Function(_$ProjectPokemonConfigImpl) then) =
      __$$ProjectPokemonConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool enabled,
      String dataRoot,
      String speciesDir,
      String learnsetsDir,
      String evolutionsDir,
      String mediaDir,
      Map<String, String> catalogFiles});
}

/// @nodoc
class __$$ProjectPokemonConfigImplCopyWithImpl<$Res>
    extends _$ProjectPokemonConfigCopyWithImpl<$Res, _$ProjectPokemonConfigImpl>
    implements _$$ProjectPokemonConfigImplCopyWith<$Res> {
  __$$ProjectPokemonConfigImplCopyWithImpl(_$ProjectPokemonConfigImpl _value,
      $Res Function(_$ProjectPokemonConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPokemonConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? dataRoot = null,
    Object? speciesDir = null,
    Object? learnsetsDir = null,
    Object? evolutionsDir = null,
    Object? mediaDir = null,
    Object? catalogFiles = null,
  }) {
    return _then(_$ProjectPokemonConfigImpl(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      dataRoot: null == dataRoot
          ? _value.dataRoot
          : dataRoot // ignore: cast_nullable_to_non_nullable
              as String,
      speciesDir: null == speciesDir
          ? _value.speciesDir
          : speciesDir // ignore: cast_nullable_to_non_nullable
              as String,
      learnsetsDir: null == learnsetsDir
          ? _value.learnsetsDir
          : learnsetsDir // ignore: cast_nullable_to_non_nullable
              as String,
      evolutionsDir: null == evolutionsDir
          ? _value.evolutionsDir
          : evolutionsDir // ignore: cast_nullable_to_non_nullable
              as String,
      mediaDir: null == mediaDir
          ? _value.mediaDir
          : mediaDir // ignore: cast_nullable_to_non_nullable
              as String,
      catalogFiles: null == catalogFiles
          ? _value._catalogFiles
          : catalogFiles // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectPokemonConfigImpl implements _ProjectPokemonConfig {
  const _$ProjectPokemonConfigImpl(
      {this.enabled = true,
      this.dataRoot = 'data/pokemon',
      this.speciesDir = 'data/pokemon/species',
      this.learnsetsDir = 'data/pokemon/learnsets',
      this.evolutionsDir = 'data/pokemon/evolutions',
      this.mediaDir = 'data/pokemon/sprite_sets',
      final Map<String, String> catalogFiles = _defaultPokemonCatalogFiles})
      : _catalogFiles = catalogFiles;

  factory _$ProjectPokemonConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectPokemonConfigImplFromJson(json);

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final String dataRoot;
  @override
  @JsonKey()
  final String speciesDir;
  @override
  @JsonKey()
  final String learnsetsDir;
  @override
  @JsonKey()
  final String evolutionsDir;
  @override
  @JsonKey()
  final String mediaDir;
  final Map<String, String> _catalogFiles;
  @override
  @JsonKey()
  Map<String, String> get catalogFiles {
    if (_catalogFiles is EqualUnmodifiableMapView) return _catalogFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_catalogFiles);
  }

  @override
  String toString() {
    return 'ProjectPokemonConfig(enabled: $enabled, dataRoot: $dataRoot, speciesDir: $speciesDir, learnsetsDir: $learnsetsDir, evolutionsDir: $evolutionsDir, mediaDir: $mediaDir, catalogFiles: $catalogFiles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPokemonConfigImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.dataRoot, dataRoot) ||
                other.dataRoot == dataRoot) &&
            (identical(other.speciesDir, speciesDir) ||
                other.speciesDir == speciesDir) &&
            (identical(other.learnsetsDir, learnsetsDir) ||
                other.learnsetsDir == learnsetsDir) &&
            (identical(other.evolutionsDir, evolutionsDir) ||
                other.evolutionsDir == evolutionsDir) &&
            (identical(other.mediaDir, mediaDir) ||
                other.mediaDir == mediaDir) &&
            const DeepCollectionEquality()
                .equals(other._catalogFiles, _catalogFiles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      enabled,
      dataRoot,
      speciesDir,
      learnsetsDir,
      evolutionsDir,
      mediaDir,
      const DeepCollectionEquality().hash(_catalogFiles));

  /// Create a copy of ProjectPokemonConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPokemonConfigImplCopyWith<_$ProjectPokemonConfigImpl>
      get copyWith =>
          __$$ProjectPokemonConfigImplCopyWithImpl<_$ProjectPokemonConfigImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectPokemonConfigImplToJson(
      this,
    );
  }
}

abstract class _ProjectPokemonConfig implements ProjectPokemonConfig {
  const factory _ProjectPokemonConfig(
      {final bool enabled,
      final String dataRoot,
      final String speciesDir,
      final String learnsetsDir,
      final String evolutionsDir,
      final String mediaDir,
      final Map<String, String> catalogFiles}) = _$ProjectPokemonConfigImpl;

  factory _ProjectPokemonConfig.fromJson(Map<String, dynamic> json) =
      _$ProjectPokemonConfigImpl.fromJson;

  @override
  bool get enabled;
  @override
  String get dataRoot;
  @override
  String get speciesDir;
  @override
  String get learnsetsDir;
  @override
  String get evolutionsDir;
  @override
  String get mediaDir;
  @override
  Map<String, String> get catalogFiles;

  /// Create a copy of ProjectPokemonConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPokemonConfigImplCopyWith<_$ProjectPokemonConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectSettings _$ProjectSettingsFromJson(Map<String, dynamic> json) {
  return _ProjectSettings.fromJson(json);
}

/// @nodoc
mixin _$ProjectSettings {
  int get tileWidth => throw _privateConstructorUsedError;
  int get tileHeight => throw _privateConstructorUsedError;
  double get displayScale => throw _privateConstructorUsedError;
  int get defaultMapWidth => throw _privateConstructorUsedError;
  int get defaultMapHeight => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId)
  String? get defaultPlayerCharacterId => throw _privateConstructorUsedError;

  /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
  ///
  /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
  /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
  @JsonKey(name: 'mistralApiKey', includeIfNull: false)
  String? get mistralApiKey => throw _privateConstructorUsedError;

  /// Serializes this ProjectSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSettingsCopyWith<ProjectSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSettingsCopyWith<$Res> {
  factory $ProjectSettingsCopyWith(
          ProjectSettings value, $Res Function(ProjectSettings) then) =
      _$ProjectSettingsCopyWithImpl<$Res, ProjectSettings>;
  @useResult
  $Res call(
      {int tileWidth,
      int tileHeight,
      double displayScale,
      int defaultMapWidth,
      int defaultMapHeight,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      String? defaultPlayerCharacterId,
      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
      String? mistralApiKey});
}

/// @nodoc
class _$ProjectSettingsCopyWithImpl<$Res, $Val extends ProjectSettings>
    implements $ProjectSettingsCopyWith<$Res> {
  _$ProjectSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileWidth = null,
    Object? tileHeight = null,
    Object? displayScale = null,
    Object? defaultMapWidth = null,
    Object? defaultMapHeight = null,
    Object? defaultPlayerCharacterId = freezed,
    Object? mistralApiKey = freezed,
  }) {
    return _then(_value.copyWith(
      tileWidth: null == tileWidth
          ? _value.tileWidth
          : tileWidth // ignore: cast_nullable_to_non_nullable
              as int,
      tileHeight: null == tileHeight
          ? _value.tileHeight
          : tileHeight // ignore: cast_nullable_to_non_nullable
              as int,
      displayScale: null == displayScale
          ? _value.displayScale
          : displayScale // ignore: cast_nullable_to_non_nullable
              as double,
      defaultMapWidth: null == defaultMapWidth
          ? _value.defaultMapWidth
          : defaultMapWidth // ignore: cast_nullable_to_non_nullable
              as int,
      defaultMapHeight: null == defaultMapHeight
          ? _value.defaultMapHeight
          : defaultMapHeight // ignore: cast_nullable_to_non_nullable
              as int,
      defaultPlayerCharacterId: freezed == defaultPlayerCharacterId
          ? _value.defaultPlayerCharacterId
          : defaultPlayerCharacterId // ignore: cast_nullable_to_non_nullable
              as String?,
      mistralApiKey: freezed == mistralApiKey
          ? _value.mistralApiKey
          : mistralApiKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectSettingsImplCopyWith<$Res>
    implements $ProjectSettingsCopyWith<$Res> {
  factory _$$ProjectSettingsImplCopyWith(_$ProjectSettingsImpl value,
          $Res Function(_$ProjectSettingsImpl) then) =
      __$$ProjectSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int tileWidth,
      int tileHeight,
      double displayScale,
      int defaultMapWidth,
      int defaultMapHeight,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      String? defaultPlayerCharacterId,
      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
      String? mistralApiKey});
}

/// @nodoc
class __$$ProjectSettingsImplCopyWithImpl<$Res>
    extends _$ProjectSettingsCopyWithImpl<$Res, _$ProjectSettingsImpl>
    implements _$$ProjectSettingsImplCopyWith<$Res> {
  __$$ProjectSettingsImplCopyWithImpl(
      _$ProjectSettingsImpl _value, $Res Function(_$ProjectSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tileWidth = null,
    Object? tileHeight = null,
    Object? displayScale = null,
    Object? defaultMapWidth = null,
    Object? defaultMapHeight = null,
    Object? defaultPlayerCharacterId = freezed,
    Object? mistralApiKey = freezed,
  }) {
    return _then(_$ProjectSettingsImpl(
      tileWidth: null == tileWidth
          ? _value.tileWidth
          : tileWidth // ignore: cast_nullable_to_non_nullable
              as int,
      tileHeight: null == tileHeight
          ? _value.tileHeight
          : tileHeight // ignore: cast_nullable_to_non_nullable
              as int,
      displayScale: null == displayScale
          ? _value.displayScale
          : displayScale // ignore: cast_nullable_to_non_nullable
              as double,
      defaultMapWidth: null == defaultMapWidth
          ? _value.defaultMapWidth
          : defaultMapWidth // ignore: cast_nullable_to_non_nullable
              as int,
      defaultMapHeight: null == defaultMapHeight
          ? _value.defaultMapHeight
          : defaultMapHeight // ignore: cast_nullable_to_non_nullable
              as int,
      defaultPlayerCharacterId: freezed == defaultPlayerCharacterId
          ? _value.defaultPlayerCharacterId
          : defaultPlayerCharacterId // ignore: cast_nullable_to_non_nullable
              as String?,
      mistralApiKey: freezed == mistralApiKey
          ? _value.mistralApiKey
          : mistralApiKey // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectSettingsImpl implements _ProjectSettings {
  const _$ProjectSettingsImpl(
      {this.tileWidth = 16,
      this.tileHeight = 16,
      this.displayScale = 2.0,
      this.defaultMapWidth = 20,
      this.defaultMapHeight = 15,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      this.defaultPlayerCharacterId,
      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
      this.mistralApiKey});

  factory _$ProjectSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSettingsImplFromJson(json);

  @override
  @JsonKey()
  final int tileWidth;
  @override
  @JsonKey()
  final int tileHeight;
  @override
  @JsonKey()
  final double displayScale;
  @override
  @JsonKey()
  final int defaultMapWidth;
  @override
  @JsonKey()
  final int defaultMapHeight;
  @override
  @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId)
  final String? defaultPlayerCharacterId;

  /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
  ///
  /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
  /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
  @override
  @JsonKey(name: 'mistralApiKey', includeIfNull: false)
  final String? mistralApiKey;

  @override
  String toString() {
    return 'ProjectSettings(tileWidth: $tileWidth, tileHeight: $tileHeight, displayScale: $displayScale, defaultMapWidth: $defaultMapWidth, defaultMapHeight: $defaultMapHeight, defaultPlayerCharacterId: $defaultPlayerCharacterId, mistralApiKey: $mistralApiKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSettingsImpl &&
            (identical(other.tileWidth, tileWidth) ||
                other.tileWidth == tileWidth) &&
            (identical(other.tileHeight, tileHeight) ||
                other.tileHeight == tileHeight) &&
            (identical(other.displayScale, displayScale) ||
                other.displayScale == displayScale) &&
            (identical(other.defaultMapWidth, defaultMapWidth) ||
                other.defaultMapWidth == defaultMapWidth) &&
            (identical(other.defaultMapHeight, defaultMapHeight) ||
                other.defaultMapHeight == defaultMapHeight) &&
            (identical(
                    other.defaultPlayerCharacterId, defaultPlayerCharacterId) ||
                other.defaultPlayerCharacterId == defaultPlayerCharacterId) &&
            (identical(other.mistralApiKey, mistralApiKey) ||
                other.mistralApiKey == mistralApiKey));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tileWidth,
      tileHeight,
      displayScale,
      defaultMapWidth,
      defaultMapHeight,
      defaultPlayerCharacterId,
      mistralApiKey);

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSettingsImplCopyWith<_$ProjectSettingsImpl> get copyWith =>
      __$$ProjectSettingsImplCopyWithImpl<_$ProjectSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSettingsImplToJson(
      this,
    );
  }
}

abstract class _ProjectSettings implements ProjectSettings {
  const factory _ProjectSettings(
      {final int tileWidth,
      final int tileHeight,
      final double displayScale,
      final int defaultMapWidth,
      final int defaultMapHeight,
      @JsonKey(
          name: 'defaultPlayerCharacterId',
          readValue: _readDefaultPlayerCharacterId)
      final String? defaultPlayerCharacterId,
      @JsonKey(name: 'mistralApiKey', includeIfNull: false)
      final String? mistralApiKey}) = _$ProjectSettingsImpl;

  factory _ProjectSettings.fromJson(Map<String, dynamic> json) =
      _$ProjectSettingsImpl.fromJson;

  @override
  int get tileWidth;
  @override
  int get tileHeight;
  @override
  double get displayScale;
  @override
  int get defaultMapWidth;
  @override
  int get defaultMapHeight;
  @override
  @JsonKey(
      name: 'defaultPlayerCharacterId',
      readValue: _readDefaultPlayerCharacterId)
  String? get defaultPlayerCharacterId;

  /// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
  ///
  /// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
  /// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
  @override
  @JsonKey(name: 'mistralApiKey', includeIfNull: false)
  String? get mistralApiKey;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSettingsImplCopyWith<_$ProjectSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectMapGroup _$ProjectMapGroupFromJson(Map<String, dynamic> json) {
  return _ProjectMapGroup.fromJson(json);
}

/// @nodoc
mixin _$ProjectMapGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  MapGroupType get type => throw _privateConstructorUsedError;
  String? get parentGroupId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  /// Serializes this ProjectMapGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectMapGroupCopyWith<ProjectMapGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectMapGroupCopyWith<$Res> {
  factory $ProjectMapGroupCopyWith(
          ProjectMapGroup value, $Res Function(ProjectMapGroup) then) =
      _$ProjectMapGroupCopyWithImpl<$Res, ProjectMapGroup>;
  @useResult
  $Res call(
      {String id,
      String name,
      MapGroupType type,
      String? parentGroupId,
      int sortOrder,
      List<String> tags,
      Map<String, dynamic> properties});
}

/// @nodoc
class _$ProjectMapGroupCopyWithImpl<$Res, $Val extends ProjectMapGroup>
    implements $ProjectMapGroupCopyWith<$Res> {
  _$ProjectMapGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
    Object? tags = null,
    Object? properties = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapGroupType,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      properties: null == properties
          ? _value.properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectMapGroupImplCopyWith<$Res>
    implements $ProjectMapGroupCopyWith<$Res> {
  factory _$$ProjectMapGroupImplCopyWith(_$ProjectMapGroupImpl value,
          $Res Function(_$ProjectMapGroupImpl) then) =
      __$$ProjectMapGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      MapGroupType type,
      String? parentGroupId,
      int sortOrder,
      List<String> tags,
      Map<String, dynamic> properties});
}

/// @nodoc
class __$$ProjectMapGroupImplCopyWithImpl<$Res>
    extends _$ProjectMapGroupCopyWithImpl<$Res, _$ProjectMapGroupImpl>
    implements _$$ProjectMapGroupImplCopyWith<$Res> {
  __$$ProjectMapGroupImplCopyWithImpl(
      _$ProjectMapGroupImpl _value, $Res Function(_$ProjectMapGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
    Object? tags = null,
    Object? properties = null,
  }) {
    return _then(_$ProjectMapGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MapGroupType,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      properties: null == properties
          ? _value._properties
          : properties // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectMapGroupImpl implements _ProjectMapGroup {
  const _$ProjectMapGroupImpl(
      {required this.id,
      required this.name,
      required this.type,
      this.parentGroupId,
      this.sortOrder = 0,
      final List<String> tags = const [],
      final Map<String, dynamic> properties = const {}})
      : _tags = tags,
        _properties = properties;

  factory _$ProjectMapGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectMapGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final MapGroupType type;
  @override
  final String? parentGroupId;
  @override
  @JsonKey()
  final int sortOrder;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final Map<String, dynamic> _properties;
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'ProjectMapGroup(id: $id, name: $name, type: $type, parentGroupId: $parentGroupId, sortOrder: $sortOrder, tags: $tags, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectMapGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.parentGroupId, parentGroupId) ||
                other.parentGroupId == parentGroupId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._properties, _properties));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      parentGroupId,
      sortOrder,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_properties));

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectMapGroupImplCopyWith<_$ProjectMapGroupImpl> get copyWith =>
      __$$ProjectMapGroupImplCopyWithImpl<_$ProjectMapGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectMapGroupImplToJson(
      this,
    );
  }
}

abstract class _ProjectMapGroup implements ProjectMapGroup {
  const factory _ProjectMapGroup(
      {required final String id,
      required final String name,
      required final MapGroupType type,
      final String? parentGroupId,
      final int sortOrder,
      final List<String> tags,
      final Map<String, dynamic> properties}) = _$ProjectMapGroupImpl;

  factory _ProjectMapGroup.fromJson(Map<String, dynamic> json) =
      _$ProjectMapGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  MapGroupType get type;
  @override
  String? get parentGroupId;
  @override
  int get sortOrder;
  @override
  List<String> get tags;
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of ProjectMapGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectMapGroupImplCopyWith<_$ProjectMapGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectMapEntry _$ProjectMapEntryFromJson(Map<String, dynamic> json) {
  return _ProjectMapEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectMapEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get relativePath => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  MapRole get role => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectMapEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectMapEntryCopyWith<ProjectMapEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectMapEntryCopyWith<$Res> {
  factory $ProjectMapEntryCopyWith(
          ProjectMapEntry value, $Res Function(ProjectMapEntry) then) =
      _$ProjectMapEntryCopyWithImpl<$Res, ProjectMapEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      String? groupId,
      MapRole role,
      int sortOrder});
}

/// @nodoc
class _$ProjectMapEntryCopyWithImpl<$Res, $Val extends ProjectMapEntry>
    implements $ProjectMapEntryCopyWith<$Res> {
  _$ProjectMapEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? groupId = freezed,
    Object? role = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MapRole,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectMapEntryImplCopyWith<$Res>
    implements $ProjectMapEntryCopyWith<$Res> {
  factory _$$ProjectMapEntryImplCopyWith(_$ProjectMapEntryImpl value,
          $Res Function(_$ProjectMapEntryImpl) then) =
      __$$ProjectMapEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      String? groupId,
      MapRole role,
      int sortOrder});
}

/// @nodoc
class __$$ProjectMapEntryImplCopyWithImpl<$Res>
    extends _$ProjectMapEntryCopyWithImpl<$Res, _$ProjectMapEntryImpl>
    implements _$$ProjectMapEntryImplCopyWith<$Res> {
  __$$ProjectMapEntryImplCopyWithImpl(
      _$ProjectMapEntryImpl _value, $Res Function(_$ProjectMapEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? groupId = freezed,
    Object? role = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectMapEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as MapRole,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectMapEntryImpl implements _ProjectMapEntry {
  const _$ProjectMapEntryImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      this.groupId,
      this.role = MapRole.exterior,
      this.sortOrder = 0});

  factory _$ProjectMapEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectMapEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;
  @override
  final String? groupId;
  @override
  @JsonKey()
  final MapRole role;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectMapEntry(id: $id, name: $name, relativePath: $relativePath, groupId: $groupId, role: $role, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectMapEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, relativePath, groupId, role, sortOrder);

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectMapEntryImplCopyWith<_$ProjectMapEntryImpl> get copyWith =>
      __$$ProjectMapEntryImplCopyWithImpl<_$ProjectMapEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectMapEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectMapEntry implements ProjectMapEntry {
  const factory _ProjectMapEntry(
      {required final String id,
      required final String name,
      required final String relativePath,
      final String? groupId,
      final MapRole role,
      final int sortOrder}) = _$ProjectMapEntryImpl;

  factory _ProjectMapEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectMapEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;
  @override
  String? get groupId;
  @override
  MapRole get role;
  @override
  int get sortOrder;

  /// Create a copy of ProjectMapEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectMapEntryImplCopyWith<_$ProjectMapEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectDialogueFolder _$ProjectDialogueFolderFromJson(
    Map<String, dynamic> json) {
  return _ProjectDialogueFolder.fromJson(json);
}

/// @nodoc
mixin _$ProjectDialogueFolder {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentFolderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectDialogueFolder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectDialogueFolderCopyWith<ProjectDialogueFolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectDialogueFolderCopyWith<$Res> {
  factory $ProjectDialogueFolderCopyWith(ProjectDialogueFolder value,
          $Res Function(ProjectDialogueFolder) then) =
      _$ProjectDialogueFolderCopyWithImpl<$Res, ProjectDialogueFolder>;
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class _$ProjectDialogueFolderCopyWithImpl<$Res,
        $Val extends ProjectDialogueFolder>
    implements $ProjectDialogueFolderCopyWith<$Res> {
  _$ProjectDialogueFolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectDialogueFolderImplCopyWith<$Res>
    implements $ProjectDialogueFolderCopyWith<$Res> {
  factory _$$ProjectDialogueFolderImplCopyWith(
          _$ProjectDialogueFolderImpl value,
          $Res Function(_$ProjectDialogueFolderImpl) then) =
      __$$ProjectDialogueFolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class __$$ProjectDialogueFolderImplCopyWithImpl<$Res>
    extends _$ProjectDialogueFolderCopyWithImpl<$Res,
        _$ProjectDialogueFolderImpl>
    implements _$$ProjectDialogueFolderImplCopyWith<$Res> {
  __$$ProjectDialogueFolderImplCopyWithImpl(_$ProjectDialogueFolderImpl _value,
      $Res Function(_$ProjectDialogueFolderImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectDialogueFolderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectDialogueFolderImpl implements _ProjectDialogueFolder {
  const _$ProjectDialogueFolderImpl(
      {required this.id,
      required this.name,
      this.parentFolderId,
      this.sortOrder = 0});

  factory _$ProjectDialogueFolderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectDialogueFolderImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentFolderId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectDialogueFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectDialogueFolderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentFolderId, parentFolderId) ||
                other.parentFolderId == parentFolderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentFolderId, sortOrder);

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectDialogueFolderImplCopyWith<_$ProjectDialogueFolderImpl>
      get copyWith => __$$ProjectDialogueFolderImplCopyWithImpl<
          _$ProjectDialogueFolderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectDialogueFolderImplToJson(
      this,
    );
  }
}

abstract class _ProjectDialogueFolder implements ProjectDialogueFolder {
  const factory _ProjectDialogueFolder(
      {required final String id,
      required final String name,
      final String? parentFolderId,
      final int sortOrder}) = _$ProjectDialogueFolderImpl;

  factory _ProjectDialogueFolder.fromJson(Map<String, dynamic> json) =
      _$ProjectDialogueFolderImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentFolderId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectDialogueFolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectDialogueFolderImplCopyWith<_$ProjectDialogueFolderImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectDialogueEntry _$ProjectDialogueEntryFromJson(Map<String, dynamic> json) {
  return _ProjectDialogueEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectDialogueEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
  String get relativePath => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
  String? get defaultStartNode => throw _privateConstructorUsedError;

  /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
  String? get folderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectDialogueEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectDialogueEntryCopyWith<ProjectDialogueEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectDialogueEntryCopyWith<$Res> {
  factory $ProjectDialogueEntryCopyWith(ProjectDialogueEntry value,
          $Res Function(ProjectDialogueEntry) then) =
      _$ProjectDialogueEntryCopyWithImpl<$Res, ProjectDialogueEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      List<String> tags,
      String description,
      String? defaultStartNode,
      String? folderId,
      int sortOrder});
}

/// @nodoc
class _$ProjectDialogueEntryCopyWithImpl<$Res,
        $Val extends ProjectDialogueEntry>
    implements $ProjectDialogueEntryCopyWith<$Res> {
  _$ProjectDialogueEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? tags = null,
    Object? description = null,
    Object? defaultStartNode = freezed,
    Object? folderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      defaultStartNode: freezed == defaultStartNode
          ? _value.defaultStartNode
          : defaultStartNode // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectDialogueEntryImplCopyWith<$Res>
    implements $ProjectDialogueEntryCopyWith<$Res> {
  factory _$$ProjectDialogueEntryImplCopyWith(_$ProjectDialogueEntryImpl value,
          $Res Function(_$ProjectDialogueEntryImpl) then) =
      __$$ProjectDialogueEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      List<String> tags,
      String description,
      String? defaultStartNode,
      String? folderId,
      int sortOrder});
}

/// @nodoc
class __$$ProjectDialogueEntryImplCopyWithImpl<$Res>
    extends _$ProjectDialogueEntryCopyWithImpl<$Res, _$ProjectDialogueEntryImpl>
    implements _$$ProjectDialogueEntryImplCopyWith<$Res> {
  __$$ProjectDialogueEntryImplCopyWithImpl(_$ProjectDialogueEntryImpl _value,
      $Res Function(_$ProjectDialogueEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? tags = null,
    Object? description = null,
    Object? defaultStartNode = freezed,
    Object? folderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectDialogueEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      defaultStartNode: freezed == defaultStartNode
          ? _value.defaultStartNode
          : defaultStartNode // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectDialogueEntryImpl implements _ProjectDialogueEntry {
  const _$ProjectDialogueEntryImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      final List<String> tags = const [],
      this.description = '',
      this.defaultStartNode,
      this.folderId,
      this.sortOrder = 0})
      : _tags = tags;

  factory _$ProjectDialogueEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectDialogueEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
  @override
  final String relativePath;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final String description;

  /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
  @override
  final String? defaultStartNode;

  /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
  @override
  final String? folderId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectDialogueEntry(id: $id, name: $name, relativePath: $relativePath, tags: $tags, description: $description, defaultStartNode: $defaultStartNode, folderId: $folderId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectDialogueEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.defaultStartNode, defaultStartNode) ||
                other.defaultStartNode == defaultStartNode) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      relativePath,
      const DeepCollectionEquality().hash(_tags),
      description,
      defaultStartNode,
      folderId,
      sortOrder);

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectDialogueEntryImplCopyWith<_$ProjectDialogueEntryImpl>
      get copyWith =>
          __$$ProjectDialogueEntryImplCopyWithImpl<_$ProjectDialogueEntryImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectDialogueEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectDialogueEntry implements ProjectDialogueEntry {
  const factory _ProjectDialogueEntry(
      {required final String id,
      required final String name,
      required final String relativePath,
      final List<String> tags,
      final String description,
      final String? defaultStartNode,
      final String? folderId,
      final int sortOrder}) = _$ProjectDialogueEntryImpl;

  factory _ProjectDialogueEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectDialogueEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
  @override
  String get relativePath;
  @override
  List<String> get tags;
  @override
  String get description;

  /// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
  @override
  String? get defaultStartNode;

  /// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
  @override
  String? get folderId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectDialogueEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectDialogueEntryImplCopyWith<_$ProjectDialogueEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTilesetFolder _$ProjectTilesetFolderFromJson(Map<String, dynamic> json) {
  return _ProjectTilesetFolder.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetFolder {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentFolderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetFolder to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetFolderCopyWith<ProjectTilesetFolder> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetFolderCopyWith<$Res> {
  factory $ProjectTilesetFolderCopyWith(ProjectTilesetFolder value,
          $Res Function(ProjectTilesetFolder) then) =
      _$ProjectTilesetFolderCopyWithImpl<$Res, ProjectTilesetFolder>;
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class _$ProjectTilesetFolderCopyWithImpl<$Res,
        $Val extends ProjectTilesetFolder>
    implements $ProjectTilesetFolderCopyWith<$Res> {
  _$ProjectTilesetFolderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetFolderImplCopyWith<$Res>
    implements $ProjectTilesetFolderCopyWith<$Res> {
  factory _$$ProjectTilesetFolderImplCopyWith(_$ProjectTilesetFolderImpl value,
          $Res Function(_$ProjectTilesetFolderImpl) then) =
      __$$ProjectTilesetFolderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentFolderId, int sortOrder});
}

/// @nodoc
class __$$ProjectTilesetFolderImplCopyWithImpl<$Res>
    extends _$ProjectTilesetFolderCopyWithImpl<$Res, _$ProjectTilesetFolderImpl>
    implements _$$ProjectTilesetFolderImplCopyWith<$Res> {
  __$$ProjectTilesetFolderImplCopyWithImpl(_$ProjectTilesetFolderImpl _value,
      $Res Function(_$ProjectTilesetFolderImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentFolderId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectTilesetFolderImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentFolderId: freezed == parentFolderId
          ? _value.parentFolderId
          : parentFolderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTilesetFolderImpl implements _ProjectTilesetFolder {
  const _$ProjectTilesetFolderImpl(
      {required this.id,
      required this.name,
      this.parentFolderId,
      this.sortOrder = 0});

  factory _$ProjectTilesetFolderImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetFolderImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentFolderId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectTilesetFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetFolderImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentFolderId, parentFolderId) ||
                other.parentFolderId == parentFolderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentFolderId, sortOrder);

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetFolderImplCopyWith<_$ProjectTilesetFolderImpl>
      get copyWith =>
          __$$ProjectTilesetFolderImplCopyWithImpl<_$ProjectTilesetFolderImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetFolderImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetFolder implements ProjectTilesetFolder {
  const factory _ProjectTilesetFolder(
      {required final String id,
      required final String name,
      final String? parentFolderId,
      final int sortOrder}) = _$ProjectTilesetFolderImpl;

  factory _ProjectTilesetFolder.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetFolderImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentFolderId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectTilesetFolder
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetFolderImplCopyWith<_$ProjectTilesetFolderImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectTilesetEntry _$ProjectTilesetEntryFromJson(Map<String, dynamic> json) {
  return _ProjectTilesetEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectTilesetEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get relativePath => throw _privateConstructorUsedError;
  TilesetScope get scope => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;

  /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
  String? get folderId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  bool get isWorldTileset => throw _privateConstructorUsedError;
  List<TilesetElementGroup> get elementGroups =>
      throw _privateConstructorUsedError;
  List<TilesetPaletteEntry> get paletteEntries =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectTilesetEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTilesetEntryCopyWith<ProjectTilesetEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTilesetEntryCopyWith<$Res> {
  factory $ProjectTilesetEntryCopyWith(
          ProjectTilesetEntry value, $Res Function(ProjectTilesetEntry) then) =
      _$ProjectTilesetEntryCopyWithImpl<$Res, ProjectTilesetEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      TilesetScope scope,
      String? groupId,
      String? folderId,
      int sortOrder,
      bool isWorldTileset,
      List<TilesetElementGroup> elementGroups,
      List<TilesetPaletteEntry> paletteEntries});
}

/// @nodoc
class _$ProjectTilesetEntryCopyWithImpl<$Res, $Val extends ProjectTilesetEntry>
    implements $ProjectTilesetEntryCopyWith<$Res> {
  _$ProjectTilesetEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? scope = null,
    Object? groupId = freezed,
    Object? folderId = freezed,
    Object? sortOrder = null,
    Object? isWorldTileset = null,
    Object? elementGroups = null,
    Object? paletteEntries = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as TilesetScope,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isWorldTileset: null == isWorldTileset
          ? _value.isWorldTileset
          : isWorldTileset // ignore: cast_nullable_to_non_nullable
              as bool,
      elementGroups: null == elementGroups
          ? _value.elementGroups
          : elementGroups // ignore: cast_nullable_to_non_nullable
              as List<TilesetElementGroup>,
      paletteEntries: null == paletteEntries
          ? _value.paletteEntries
          : paletteEntries // ignore: cast_nullable_to_non_nullable
              as List<TilesetPaletteEntry>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTilesetEntryImplCopyWith<$Res>
    implements $ProjectTilesetEntryCopyWith<$Res> {
  factory _$$ProjectTilesetEntryImplCopyWith(_$ProjectTilesetEntryImpl value,
          $Res Function(_$ProjectTilesetEntryImpl) then) =
      __$$ProjectTilesetEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String relativePath,
      TilesetScope scope,
      String? groupId,
      String? folderId,
      int sortOrder,
      bool isWorldTileset,
      List<TilesetElementGroup> elementGroups,
      List<TilesetPaletteEntry> paletteEntries});
}

/// @nodoc
class __$$ProjectTilesetEntryImplCopyWithImpl<$Res>
    extends _$ProjectTilesetEntryCopyWithImpl<$Res, _$ProjectTilesetEntryImpl>
    implements _$$ProjectTilesetEntryImplCopyWith<$Res> {
  __$$ProjectTilesetEntryImplCopyWithImpl(_$ProjectTilesetEntryImpl _value,
      $Res Function(_$ProjectTilesetEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? relativePath = null,
    Object? scope = null,
    Object? groupId = freezed,
    Object? folderId = freezed,
    Object? sortOrder = null,
    Object? isWorldTileset = null,
    Object? elementGroups = null,
    Object? paletteEntries = null,
  }) {
    return _then(_$ProjectTilesetEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      relativePath: null == relativePath
          ? _value.relativePath
          : relativePath // ignore: cast_nullable_to_non_nullable
              as String,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as TilesetScope,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      folderId: freezed == folderId
          ? _value.folderId
          : folderId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      isWorldTileset: null == isWorldTileset
          ? _value.isWorldTileset
          : isWorldTileset // ignore: cast_nullable_to_non_nullable
              as bool,
      elementGroups: null == elementGroups
          ? _value._elementGroups
          : elementGroups // ignore: cast_nullable_to_non_nullable
              as List<TilesetElementGroup>,
      paletteEntries: null == paletteEntries
          ? _value._paletteEntries
          : paletteEntries // ignore: cast_nullable_to_non_nullable
              as List<TilesetPaletteEntry>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTilesetEntryImpl implements _ProjectTilesetEntry {
  const _$ProjectTilesetEntryImpl(
      {required this.id,
      required this.name,
      required this.relativePath,
      this.scope = TilesetScope.global,
      this.groupId,
      this.folderId,
      this.sortOrder = 0,
      this.isWorldTileset = false,
      final List<TilesetElementGroup> elementGroups = const [],
      final List<TilesetPaletteEntry> paletteEntries = const []})
      : _elementGroups = elementGroups,
        _paletteEntries = paletteEntries;

  factory _$ProjectTilesetEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTilesetEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String relativePath;
  @override
  @JsonKey()
  final TilesetScope scope;
  @override
  final String? groupId;

  /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
  @override
  final String? folderId;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  @JsonKey()
  final bool isWorldTileset;
  final List<TilesetElementGroup> _elementGroups;
  @override
  @JsonKey()
  List<TilesetElementGroup> get elementGroups {
    if (_elementGroups is EqualUnmodifiableListView) return _elementGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elementGroups);
  }

  final List<TilesetPaletteEntry> _paletteEntries;
  @override
  @JsonKey()
  List<TilesetPaletteEntry> get paletteEntries {
    if (_paletteEntries is EqualUnmodifiableListView) return _paletteEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_paletteEntries);
  }

  @override
  String toString() {
    return 'ProjectTilesetEntry(id: $id, name: $name, relativePath: $relativePath, scope: $scope, groupId: $groupId, folderId: $folderId, sortOrder: $sortOrder, isWorldTileset: $isWorldTileset, elementGroups: $elementGroups, paletteEntries: $paletteEntries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTilesetEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.relativePath, relativePath) ||
                other.relativePath == relativePath) &&
            (identical(other.scope, scope) || other.scope == scope) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isWorldTileset, isWorldTileset) ||
                other.isWorldTileset == isWorldTileset) &&
            const DeepCollectionEquality()
                .equals(other._elementGroups, _elementGroups) &&
            const DeepCollectionEquality()
                .equals(other._paletteEntries, _paletteEntries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      relativePath,
      scope,
      groupId,
      folderId,
      sortOrder,
      isWorldTileset,
      const DeepCollectionEquality().hash(_elementGroups),
      const DeepCollectionEquality().hash(_paletteEntries));

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTilesetEntryImplCopyWith<_$ProjectTilesetEntryImpl> get copyWith =>
      __$$ProjectTilesetEntryImplCopyWithImpl<_$ProjectTilesetEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTilesetEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectTilesetEntry implements ProjectTilesetEntry {
  const factory _ProjectTilesetEntry(
          {required final String id,
          required final String name,
          required final String relativePath,
          final TilesetScope scope,
          final String? groupId,
          final String? folderId,
          final int sortOrder,
          final bool isWorldTileset,
          final List<TilesetElementGroup> elementGroups,
          final List<TilesetPaletteEntry> paletteEntries}) =
      _$ProjectTilesetEntryImpl;

  factory _ProjectTilesetEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectTilesetEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get relativePath;
  @override
  TilesetScope get scope;
  @override
  String? get groupId;

  /// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
  @override
  String? get folderId;
  @override
  int get sortOrder;
  @override
  bool get isWorldTileset;
  @override
  List<TilesetElementGroup> get elementGroups;
  @override
  List<TilesetPaletteEntry> get paletteEntries;

  /// Create a copy of ProjectTilesetEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTilesetEntryImplCopyWith<_$ProjectTilesetEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetPaletteEntry _$TilesetPaletteEntryFromJson(Map<String, dynamic> json) {
  return _TilesetPaletteEntry.fromJson(json);
}

/// @nodoc
mixin _$TilesetPaletteEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  PaletteCategory get category => throw _privateConstructorUsedError;

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;
  String? get recommendedLayerId => throw _privateConstructorUsedError;

  /// Serializes this TilesetPaletteEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetPaletteEntryCopyWith<TilesetPaletteEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetPaletteEntryCopyWith<$Res> {
  factory $TilesetPaletteEntryCopyWith(
          TilesetPaletteEntry value, $Res Function(TilesetPaletteEntry) then) =
      _$TilesetPaletteEntryCopyWithImpl<$Res, TilesetPaletteEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      PaletteCategory category,
      List<TilesetVisualFrame> frames,
      String? recommendedLayerId});
}

/// @nodoc
class _$TilesetPaletteEntryCopyWithImpl<$Res, $Val extends TilesetPaletteEntry>
    implements $TilesetPaletteEntryCopyWith<$Res> {
  _$TilesetPaletteEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? frames = null,
    Object? recommendedLayerId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PaletteCategory,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilesetPaletteEntryImplCopyWith<$Res>
    implements $TilesetPaletteEntryCopyWith<$Res> {
  factory _$$TilesetPaletteEntryImplCopyWith(_$TilesetPaletteEntryImpl value,
          $Res Function(_$TilesetPaletteEntryImpl) then) =
      __$$TilesetPaletteEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      PaletteCategory category,
      List<TilesetVisualFrame> frames,
      String? recommendedLayerId});
}

/// @nodoc
class __$$TilesetPaletteEntryImplCopyWithImpl<$Res>
    extends _$TilesetPaletteEntryCopyWithImpl<$Res, _$TilesetPaletteEntryImpl>
    implements _$$TilesetPaletteEntryImplCopyWith<$Res> {
  __$$TilesetPaletteEntryImplCopyWithImpl(_$TilesetPaletteEntryImpl _value,
      $Res Function(_$TilesetPaletteEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? frames = null,
    Object? recommendedLayerId = freezed,
  }) {
    return _then(_$TilesetPaletteEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PaletteCategory,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TilesetPaletteEntryImpl implements _TilesetPaletteEntry {
  const _$TilesetPaletteEntryImpl(
      {required this.id,
      this.name = '',
      this.category = PaletteCategory.uncategorized,
      required final List<TilesetVisualFrame> frames,
      this.recommendedLayerId})
      : _frames = frames;

  factory _$TilesetPaletteEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetPaletteEntryImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final PaletteCategory category;

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  final String? recommendedLayerId;

  @override
  String toString() {
    return 'TilesetPaletteEntry(id: $id, name: $name, category: $category, frames: $frames, recommendedLayerId: $recommendedLayerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetPaletteEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.recommendedLayerId, recommendedLayerId) ||
                other.recommendedLayerId == recommendedLayerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, category,
      const DeepCollectionEquality().hash(_frames), recommendedLayerId);

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetPaletteEntryImplCopyWith<_$TilesetPaletteEntryImpl> get copyWith =>
      __$$TilesetPaletteEntryImplCopyWithImpl<_$TilesetPaletteEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetPaletteEntryImplToJson(
      this,
    );
  }
}

abstract class _TilesetPaletteEntry implements TilesetPaletteEntry {
  const factory _TilesetPaletteEntry(
      {required final String id,
      final String name,
      final PaletteCategory category,
      required final List<TilesetVisualFrame> frames,
      final String? recommendedLayerId}) = _$TilesetPaletteEntryImpl;

  factory _TilesetPaletteEntry.fromJson(Map<String, dynamic> json) =
      _$TilesetPaletteEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  PaletteCategory get category;

  /// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
  @override
  List<TilesetVisualFrame> get frames;
  @override
  String? get recommendedLayerId;

  /// Create a copy of TilesetPaletteEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetPaletteEntryImplCopyWith<_$TilesetPaletteEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetSourceRect _$TilesetSourceRectFromJson(Map<String, dynamic> json) {
  return _TilesetSourceRect.fromJson(json);
}

/// @nodoc
mixin _$TilesetSourceRect {
  int get x => throw _privateConstructorUsedError;
  int get y => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;

  /// Serializes this TilesetSourceRect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetSourceRectCopyWith<TilesetSourceRect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetSourceRectCopyWith<$Res> {
  factory $TilesetSourceRectCopyWith(
          TilesetSourceRect value, $Res Function(TilesetSourceRect) then) =
      _$TilesetSourceRectCopyWithImpl<$Res, TilesetSourceRect>;
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class _$TilesetSourceRectCopyWithImpl<$Res, $Val extends TilesetSourceRect>
    implements $TilesetSourceRectCopyWith<$Res> {
  _$TilesetSourceRectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilesetSourceRectImplCopyWith<$Res>
    implements $TilesetSourceRectCopyWith<$Res> {
  factory _$$TilesetSourceRectImplCopyWith(_$TilesetSourceRectImpl value,
          $Res Function(_$TilesetSourceRectImpl) then) =
      __$$TilesetSourceRectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int x, int y, int width, int height});
}

/// @nodoc
class __$$TilesetSourceRectImplCopyWithImpl<$Res>
    extends _$TilesetSourceRectCopyWithImpl<$Res, _$TilesetSourceRectImpl>
    implements _$$TilesetSourceRectImplCopyWith<$Res> {
  __$$TilesetSourceRectImplCopyWithImpl(_$TilesetSourceRectImpl _value,
      $Res Function(_$TilesetSourceRectImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$TilesetSourceRectImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as int,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilesetSourceRectImpl implements _TilesetSourceRect {
  const _$TilesetSourceRectImpl(
      {required this.x, required this.y, this.width = 1, this.height = 1});

  factory _$TilesetSourceRectImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetSourceRectImplFromJson(json);

  @override
  final int x;
  @override
  final int y;
  @override
  @JsonKey()
  final int width;
  @override
  @JsonKey()
  final int height;

  @override
  String toString() {
    return 'TilesetSourceRect(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetSourceRectImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, width, height);

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetSourceRectImplCopyWith<_$TilesetSourceRectImpl> get copyWith =>
      __$$TilesetSourceRectImplCopyWithImpl<_$TilesetSourceRectImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetSourceRectImplToJson(
      this,
    );
  }
}

abstract class _TilesetSourceRect implements TilesetSourceRect {
  const factory _TilesetSourceRect(
      {required final int x,
      required final int y,
      final int width,
      final int height}) = _$TilesetSourceRectImpl;

  factory _TilesetSourceRect.fromJson(Map<String, dynamic> json) =
      _$TilesetSourceRectImpl.fromJson;

  @override
  int get x;
  @override
  int get y;
  @override
  int get width;
  @override
  int get height;

  /// Create a copy of TilesetSourceRect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetSourceRectImplCopyWith<_$TilesetSourceRectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetVisualFrame _$TilesetVisualFrameFromJson(Map<String, dynamic> json) {
  return _TilesetVisualFrame.fromJson(json);
}

/// @nodoc
mixin _$TilesetVisualFrame {
  String get tilesetId => throw _privateConstructorUsedError;
  TilesetSourceRect get source => throw _privateConstructorUsedError;

  /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
  int? get durationMs => throw _privateConstructorUsedError;

  /// Serializes this TilesetVisualFrame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetVisualFrameCopyWith<TilesetVisualFrame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetVisualFrameCopyWith<$Res> {
  factory $TilesetVisualFrameCopyWith(
          TilesetVisualFrame value, $Res Function(TilesetVisualFrame) then) =
      _$TilesetVisualFrameCopyWithImpl<$Res, TilesetVisualFrame>;
  @useResult
  $Res call({String tilesetId, TilesetSourceRect source, int? durationMs});

  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class _$TilesetVisualFrameCopyWithImpl<$Res, $Val extends TilesetVisualFrame>
    implements $TilesetVisualFrameCopyWith<$Res> {
  _$TilesetVisualFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tilesetId = null,
    Object? source = null,
    Object? durationMs = freezed,
  }) {
    return _then(_value.copyWith(
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TilesetSourceRectCopyWith<$Res> get source {
    return $TilesetSourceRectCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TilesetVisualFrameImplCopyWith<$Res>
    implements $TilesetVisualFrameCopyWith<$Res> {
  factory _$$TilesetVisualFrameImplCopyWith(_$TilesetVisualFrameImpl value,
          $Res Function(_$TilesetVisualFrameImpl) then) =
      __$$TilesetVisualFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String tilesetId, TilesetSourceRect source, int? durationMs});

  @override
  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class __$$TilesetVisualFrameImplCopyWithImpl<$Res>
    extends _$TilesetVisualFrameCopyWithImpl<$Res, _$TilesetVisualFrameImpl>
    implements _$$TilesetVisualFrameImplCopyWith<$Res> {
  __$$TilesetVisualFrameImplCopyWithImpl(_$TilesetVisualFrameImpl _value,
      $Res Function(_$TilesetVisualFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tilesetId = null,
    Object? source = null,
    Object? durationMs = freezed,
  }) {
    return _then(_$TilesetVisualFrameImpl(
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: freezed == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TilesetVisualFrameImpl implements _TilesetVisualFrame {
  const _$TilesetVisualFrameImpl(
      {this.tilesetId = '', required this.source, this.durationMs});

  factory _$TilesetVisualFrameImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetVisualFrameImplFromJson(json);

  @override
  @JsonKey()
  final String tilesetId;
  @override
  final TilesetSourceRect source;

  /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
  @override
  final int? durationMs;

  @override
  String toString() {
    return 'TilesetVisualFrame(tilesetId: $tilesetId, source: $source, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetVisualFrameImpl &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tilesetId, source, durationMs);

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetVisualFrameImplCopyWith<_$TilesetVisualFrameImpl> get copyWith =>
      __$$TilesetVisualFrameImplCopyWithImpl<_$TilesetVisualFrameImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetVisualFrameImplToJson(
      this,
    );
  }
}

abstract class _TilesetVisualFrame implements TilesetVisualFrame {
  const factory _TilesetVisualFrame(
      {final String tilesetId,
      required final TilesetSourceRect source,
      final int? durationMs}) = _$TilesetVisualFrameImpl;

  factory _TilesetVisualFrame.fromJson(Map<String, dynamic> json) =
      _$TilesetVisualFrameImpl.fromJson;

  @override
  String get tilesetId;
  @override
  TilesetSourceRect get source;

  /// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
  @override
  int? get durationMs;

  /// Create a copy of TilesetVisualFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetVisualFrameImplCopyWith<_$TilesetVisualFrameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TilesetElementGroup _$TilesetElementGroupFromJson(Map<String, dynamic> json) {
  return _TilesetElementGroup.fromJson(json);
}

/// @nodoc
mixin _$TilesetElementGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentGroupId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this TilesetElementGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TilesetElementGroupCopyWith<TilesetElementGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TilesetElementGroupCopyWith<$Res> {
  factory $TilesetElementGroupCopyWith(
          TilesetElementGroup value, $Res Function(TilesetElementGroup) then) =
      _$TilesetElementGroupCopyWithImpl<$Res, TilesetElementGroup>;
  @useResult
  $Res call({String id, String name, String? parentGroupId, int sortOrder});
}

/// @nodoc
class _$TilesetElementGroupCopyWithImpl<$Res, $Val extends TilesetElementGroup>
    implements $TilesetElementGroupCopyWith<$Res> {
  _$TilesetElementGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TilesetElementGroupImplCopyWith<$Res>
    implements $TilesetElementGroupCopyWith<$Res> {
  factory _$$TilesetElementGroupImplCopyWith(_$TilesetElementGroupImpl value,
          $Res Function(_$TilesetElementGroupImpl) then) =
      __$$TilesetElementGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentGroupId, int sortOrder});
}

/// @nodoc
class __$$TilesetElementGroupImplCopyWithImpl<$Res>
    extends _$TilesetElementGroupCopyWithImpl<$Res, _$TilesetElementGroupImpl>
    implements _$$TilesetElementGroupImplCopyWith<$Res> {
  __$$TilesetElementGroupImplCopyWithImpl(_$TilesetElementGroupImpl _value,
      $Res Function(_$TilesetElementGroupImpl) _then)
      : super(_value, _then);

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentGroupId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$TilesetElementGroupImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentGroupId: freezed == parentGroupId
          ? _value.parentGroupId
          : parentGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TilesetElementGroupImpl implements _TilesetElementGroup {
  const _$TilesetElementGroupImpl(
      {required this.id,
      required this.name,
      this.parentGroupId,
      this.sortOrder = 0});

  factory _$TilesetElementGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$TilesetElementGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentGroupId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'TilesetElementGroup(id: $id, name: $name, parentGroupId: $parentGroupId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TilesetElementGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentGroupId, parentGroupId) ||
                other.parentGroupId == parentGroupId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentGroupId, sortOrder);

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TilesetElementGroupImplCopyWith<_$TilesetElementGroupImpl> get copyWith =>
      __$$TilesetElementGroupImplCopyWithImpl<_$TilesetElementGroupImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TilesetElementGroupImplToJson(
      this,
    );
  }
}

abstract class _TilesetElementGroup implements TilesetElementGroup {
  const factory _TilesetElementGroup(
      {required final String id,
      required final String name,
      final String? parentGroupId,
      final int sortOrder}) = _$TilesetElementGroupImpl;

  factory _TilesetElementGroup.fromJson(Map<String, dynamic> json) =
      _$TilesetElementGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentGroupId;
  @override
  int get sortOrder;

  /// Create a copy of TilesetElementGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TilesetElementGroupImplCopyWith<_$TilesetElementGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectElementCategory _$ProjectElementCategoryFromJson(
    Map<String, dynamic> json) {
  return _ProjectElementCategory.fromJson(json);
}

/// @nodoc
mixin _$ProjectElementCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentCategoryId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectElementCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectElementCategoryCopyWith<ProjectElementCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectElementCategoryCopyWith<$Res> {
  factory $ProjectElementCategoryCopyWith(ProjectElementCategory value,
          $Res Function(ProjectElementCategory) then) =
      _$ProjectElementCategoryCopyWithImpl<$Res, ProjectElementCategory>;
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class _$ProjectElementCategoryCopyWithImpl<$Res,
        $Val extends ProjectElementCategory>
    implements $ProjectElementCategoryCopyWith<$Res> {
  _$ProjectElementCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentCategoryId: freezed == parentCategoryId
          ? _value.parentCategoryId
          : parentCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectElementCategoryImplCopyWith<$Res>
    implements $ProjectElementCategoryCopyWith<$Res> {
  factory _$$ProjectElementCategoryImplCopyWith(
          _$ProjectElementCategoryImpl value,
          $Res Function(_$ProjectElementCategoryImpl) then) =
      __$$ProjectElementCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class __$$ProjectElementCategoryImplCopyWithImpl<$Res>
    extends _$ProjectElementCategoryCopyWithImpl<$Res,
        _$ProjectElementCategoryImpl>
    implements _$$ProjectElementCategoryImplCopyWith<$Res> {
  __$$ProjectElementCategoryImplCopyWithImpl(
      _$ProjectElementCategoryImpl _value,
      $Res Function(_$ProjectElementCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectElementCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentCategoryId: freezed == parentCategoryId
          ? _value.parentCategoryId
          : parentCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectElementCategoryImpl implements _ProjectElementCategory {
  const _$ProjectElementCategoryImpl(
      {required this.id,
      required this.name,
      this.parentCategoryId,
      this.sortOrder = 0});

  factory _$ProjectElementCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectElementCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentCategoryId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectElementCategory(id: $id, name: $name, parentCategoryId: $parentCategoryId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectElementCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentCategoryId, parentCategoryId) ||
                other.parentCategoryId == parentCategoryId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentCategoryId, sortOrder);

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectElementCategoryImplCopyWith<_$ProjectElementCategoryImpl>
      get copyWith => __$$ProjectElementCategoryImplCopyWithImpl<
          _$ProjectElementCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectElementCategoryImplToJson(
      this,
    );
  }
}

abstract class _ProjectElementCategory implements ProjectElementCategory {
  const factory _ProjectElementCategory(
      {required final String id,
      required final String name,
      final String? parentCategoryId,
      final int sortOrder}) = _$ProjectElementCategoryImpl;

  factory _ProjectElementCategory.fromJson(Map<String, dynamic> json) =
      _$ProjectElementCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentCategoryId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectElementCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectElementCategoryImplCopyWith<_$ProjectElementCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectElementEntry _$ProjectElementEntryFromJson(Map<String, dynamic> json) {
  return _ProjectElementEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectElementEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  String get categoryId => throw _privateConstructorUsedError;
  String? get tilesetGroupId => throw _privateConstructorUsedError;

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;
  ElementPresetKind get presetKind => throw _privateConstructorUsedError;
  ElementCollisionProfile? get collisionProfile =>
      throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  String? get recommendedLayerId => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectElementEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectElementEntryCopyWith<ProjectElementEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectElementEntryCopyWith<$Res> {
  factory $ProjectElementEntryCopyWith(
          ProjectElementEntry value, $Res Function(ProjectElementEntry) then) =
      _$ProjectElementEntryCopyWithImpl<$Res, ProjectElementEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      String categoryId,
      String? tilesetGroupId,
      List<TilesetVisualFrame> frames,
      ElementPresetKind presetKind,
      ElementCollisionProfile? collisionProfile,
      String? groupId,
      String? recommendedLayerId,
      List<String> tags,
      int sortOrder});

  $ElementCollisionProfileCopyWith<$Res>? get collisionProfile;
}

/// @nodoc
class _$ProjectElementEntryCopyWithImpl<$Res, $Val extends ProjectElementEntry>
    implements $ProjectElementEntryCopyWith<$Res> {
  _$ProjectElementEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? categoryId = null,
    Object? tilesetGroupId = freezed,
    Object? frames = null,
    Object? presetKind = null,
    Object? collisionProfile = freezed,
    Object? groupId = freezed,
    Object? recommendedLayerId = freezed,
    Object? tags = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetGroupId: freezed == tilesetGroupId
          ? _value.tilesetGroupId
          : tilesetGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      presetKind: null == presetKind
          ? _value.presetKind
          : presetKind // ignore: cast_nullable_to_non_nullable
              as ElementPresetKind,
      collisionProfile: freezed == collisionProfile
          ? _value.collisionProfile
          : collisionProfile // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfile?,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ElementCollisionProfileCopyWith<$Res>? get collisionProfile {
    if (_value.collisionProfile == null) {
      return null;
    }

    return $ElementCollisionProfileCopyWith<$Res>(_value.collisionProfile!,
        (value) {
      return _then(_value.copyWith(collisionProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectElementEntryImplCopyWith<$Res>
    implements $ProjectElementEntryCopyWith<$Res> {
  factory _$$ProjectElementEntryImplCopyWith(_$ProjectElementEntryImpl value,
          $Res Function(_$ProjectElementEntryImpl) then) =
      __$$ProjectElementEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      String categoryId,
      String? tilesetGroupId,
      List<TilesetVisualFrame> frames,
      ElementPresetKind presetKind,
      ElementCollisionProfile? collisionProfile,
      String? groupId,
      String? recommendedLayerId,
      List<String> tags,
      int sortOrder});

  @override
  $ElementCollisionProfileCopyWith<$Res>? get collisionProfile;
}

/// @nodoc
class __$$ProjectElementEntryImplCopyWithImpl<$Res>
    extends _$ProjectElementEntryCopyWithImpl<$Res, _$ProjectElementEntryImpl>
    implements _$$ProjectElementEntryImplCopyWith<$Res> {
  __$$ProjectElementEntryImplCopyWithImpl(_$ProjectElementEntryImpl _value,
      $Res Function(_$ProjectElementEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? categoryId = null,
    Object? tilesetGroupId = freezed,
    Object? frames = null,
    Object? presetKind = null,
    Object? collisionProfile = freezed,
    Object? groupId = freezed,
    Object? recommendedLayerId = freezed,
    Object? tags = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectElementEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetGroupId: freezed == tilesetGroupId
          ? _value.tilesetGroupId
          : tilesetGroupId // ignore: cast_nullable_to_non_nullable
              as String?,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      presetKind: null == presetKind
          ? _value.presetKind
          : presetKind // ignore: cast_nullable_to_non_nullable
              as ElementPresetKind,
      collisionProfile: freezed == collisionProfile
          ? _value.collisionProfile
          : collisionProfile // ignore: cast_nullable_to_non_nullable
              as ElementCollisionProfile?,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      recommendedLayerId: freezed == recommendedLayerId
          ? _value.recommendedLayerId
          : recommendedLayerId // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectElementEntryImpl implements _ProjectElementEntry {
  const _$ProjectElementEntryImpl(
      {required this.id,
      required this.name,
      required this.tilesetId,
      required this.categoryId,
      this.tilesetGroupId,
      required final List<TilesetVisualFrame> frames,
      this.presetKind = ElementPresetKind.generic,
      this.collisionProfile,
      this.groupId,
      this.recommendedLayerId,
      final List<String> tags = const [],
      this.sortOrder = 0})
      : _frames = frames,
        _tags = tags;

  factory _$ProjectElementEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectElementEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String tilesetId;
  @override
  final String categoryId;
  @override
  final String? tilesetGroupId;

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  @JsonKey()
  final ElementPresetKind presetKind;
  @override
  final ElementCollisionProfile? collisionProfile;
  @override
  final String? groupId;
  @override
  final String? recommendedLayerId;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectElementEntry(id: $id, name: $name, tilesetId: $tilesetId, categoryId: $categoryId, tilesetGroupId: $tilesetGroupId, frames: $frames, presetKind: $presetKind, collisionProfile: $collisionProfile, groupId: $groupId, recommendedLayerId: $recommendedLayerId, tags: $tags, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectElementEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.tilesetGroupId, tilesetGroupId) ||
                other.tilesetGroupId == tilesetGroupId) &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.presetKind, presetKind) ||
                other.presetKind == presetKind) &&
            (identical(other.collisionProfile, collisionProfile) ||
                other.collisionProfile == collisionProfile) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.recommendedLayerId, recommendedLayerId) ||
                other.recommendedLayerId == recommendedLayerId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      tilesetId,
      categoryId,
      tilesetGroupId,
      const DeepCollectionEquality().hash(_frames),
      presetKind,
      collisionProfile,
      groupId,
      recommendedLayerId,
      const DeepCollectionEquality().hash(_tags),
      sortOrder);

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectElementEntryImplCopyWith<_$ProjectElementEntryImpl> get copyWith =>
      __$$ProjectElementEntryImplCopyWithImpl<_$ProjectElementEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectElementEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectElementEntry implements ProjectElementEntry {
  const factory _ProjectElementEntry(
      {required final String id,
      required final String name,
      required final String tilesetId,
      required final String categoryId,
      final String? tilesetGroupId,
      required final List<TilesetVisualFrame> frames,
      final ElementPresetKind presetKind,
      final ElementCollisionProfile? collisionProfile,
      final String? groupId,
      final String? recommendedLayerId,
      final List<String> tags,
      final int sortOrder}) = _$ProjectElementEntryImpl;

  factory _ProjectElementEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectElementEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get tilesetId;
  @override
  String get categoryId;
  @override
  String? get tilesetGroupId;

  /// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
  @override
  List<TilesetVisualFrame> get frames;
  @override
  ElementPresetKind get presetKind;
  @override
  ElementCollisionProfile? get collisionProfile;
  @override
  String? get groupId;
  @override
  String? get recommendedLayerId;
  @override
  List<String> get tags;
  @override
  int get sortOrder;

  /// Create a copy of ProjectElementEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectElementEntryImplCopyWith<_$ProjectElementEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectTerrainPreset _$ProjectTerrainPresetFromJson(Map<String, dynamic> json) {
  return _ProjectTerrainPreset.fromJson(json);
}

/// @nodoc
mixin _$ProjectTerrainPreset {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  TerrainType get terrainType => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<TerrainPresetVariant> get variants => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectTerrainPreset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectTerrainPresetCopyWith<ProjectTerrainPreset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectTerrainPresetCopyWith<$Res> {
  factory $ProjectTerrainPresetCopyWith(ProjectTerrainPreset value,
          $Res Function(ProjectTerrainPreset) then) =
      _$ProjectTerrainPresetCopyWithImpl<$Res, ProjectTerrainPreset>;
  @useResult
  $Res call(
      {String id,
      String name,
      TerrainType terrainType,
      String? categoryId,
      String tilesetId,
      List<TerrainPresetVariant> variants,
      int sortOrder});
}

/// @nodoc
class _$ProjectTerrainPresetCopyWithImpl<$Res,
        $Val extends ProjectTerrainPreset>
    implements $ProjectTerrainPresetCopyWith<$Res> {
  _$ProjectTerrainPresetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? terrainType = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      terrainType: null == terrainType
          ? _value.terrainType
          : terrainType // ignore: cast_nullable_to_non_nullable
              as TerrainType,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value.variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<TerrainPresetVariant>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectTerrainPresetImplCopyWith<$Res>
    implements $ProjectTerrainPresetCopyWith<$Res> {
  factory _$$ProjectTerrainPresetImplCopyWith(_$ProjectTerrainPresetImpl value,
          $Res Function(_$ProjectTerrainPresetImpl) then) =
      __$$ProjectTerrainPresetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      TerrainType terrainType,
      String? categoryId,
      String tilesetId,
      List<TerrainPresetVariant> variants,
      int sortOrder});
}

/// @nodoc
class __$$ProjectTerrainPresetImplCopyWithImpl<$Res>
    extends _$ProjectTerrainPresetCopyWithImpl<$Res, _$ProjectTerrainPresetImpl>
    implements _$$ProjectTerrainPresetImplCopyWith<$Res> {
  __$$ProjectTerrainPresetImplCopyWithImpl(_$ProjectTerrainPresetImpl _value,
      $Res Function(_$ProjectTerrainPresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? terrainType = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectTerrainPresetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      terrainType: null == terrainType
          ? _value.terrainType
          : terrainType // ignore: cast_nullable_to_non_nullable
              as TerrainType,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value._variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<TerrainPresetVariant>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectTerrainPresetImpl implements _ProjectTerrainPreset {
  const _$ProjectTerrainPresetImpl(
      {required this.id,
      required this.name,
      required this.terrainType,
      this.categoryId,
      this.tilesetId = '',
      final List<TerrainPresetVariant> variants = const [],
      this.sortOrder = 0})
      : _variants = variants;

  factory _$ProjectTerrainPresetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectTerrainPresetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final TerrainType terrainType;
  @override
  final String? categoryId;
  @override
  @JsonKey()
  final String tilesetId;
  final List<TerrainPresetVariant> _variants;
  @override
  @JsonKey()
  List<TerrainPresetVariant> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectTerrainPreset(id: $id, name: $name, terrainType: $terrainType, categoryId: $categoryId, tilesetId: $tilesetId, variants: $variants, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectTerrainPresetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.terrainType, terrainType) ||
                other.terrainType == terrainType) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      terrainType,
      categoryId,
      tilesetId,
      const DeepCollectionEquality().hash(_variants),
      sortOrder);

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectTerrainPresetImplCopyWith<_$ProjectTerrainPresetImpl>
      get copyWith =>
          __$$ProjectTerrainPresetImplCopyWithImpl<_$ProjectTerrainPresetImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectTerrainPresetImplToJson(
      this,
    );
  }
}

abstract class _ProjectTerrainPreset implements ProjectTerrainPreset {
  const factory _ProjectTerrainPreset(
      {required final String id,
      required final String name,
      required final TerrainType terrainType,
      final String? categoryId,
      final String tilesetId,
      final List<TerrainPresetVariant> variants,
      final int sortOrder}) = _$ProjectTerrainPresetImpl;

  factory _ProjectTerrainPreset.fromJson(Map<String, dynamic> json) =
      _$ProjectTerrainPresetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  TerrainType get terrainType;
  @override
  String? get categoryId;
  @override
  String get tilesetId;
  @override
  List<TerrainPresetVariant> get variants;
  @override
  int get sortOrder;

  /// Create a copy of ProjectTerrainPreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectTerrainPresetImplCopyWith<_$ProjectTerrainPresetImpl>
      get copyWith => throw _privateConstructorUsedError;
}

TerrainPresetVariant _$TerrainPresetVariantFromJson(Map<String, dynamic> json) {
  return _TerrainPresetVariant.fromJson(json);
}

/// @nodoc
mixin _$TerrainPresetVariant {
  /// Au moins une frame ; rendu éditeur = première frame.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;
  int get weight => throw _privateConstructorUsedError;

  /// Serializes this TerrainPresetVariant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TerrainPresetVariantCopyWith<TerrainPresetVariant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TerrainPresetVariantCopyWith<$Res> {
  factory $TerrainPresetVariantCopyWith(TerrainPresetVariant value,
          $Res Function(TerrainPresetVariant) then) =
      _$TerrainPresetVariantCopyWithImpl<$Res, TerrainPresetVariant>;
  @useResult
  $Res call({List<TilesetVisualFrame> frames, int weight});
}

/// @nodoc
class _$TerrainPresetVariantCopyWithImpl<$Res,
        $Val extends TerrainPresetVariant>
    implements $TerrainPresetVariantCopyWith<$Res> {
  _$TerrainPresetVariantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frames = null,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TerrainPresetVariantImplCopyWith<$Res>
    implements $TerrainPresetVariantCopyWith<$Res> {
  factory _$$TerrainPresetVariantImplCopyWith(_$TerrainPresetVariantImpl value,
          $Res Function(_$TerrainPresetVariantImpl) then) =
      __$$TerrainPresetVariantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<TilesetVisualFrame> frames, int weight});
}

/// @nodoc
class __$$TerrainPresetVariantImplCopyWithImpl<$Res>
    extends _$TerrainPresetVariantCopyWithImpl<$Res, _$TerrainPresetVariantImpl>
    implements _$$TerrainPresetVariantImplCopyWith<$Res> {
  __$$TerrainPresetVariantImplCopyWithImpl(_$TerrainPresetVariantImpl _value,
      $Res Function(_$TerrainPresetVariantImpl) _then)
      : super(_value, _then);

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frames = null,
    Object? weight = null,
  }) {
    return _then(_$TerrainPresetVariantImpl(
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$TerrainPresetVariantImpl implements _TerrainPresetVariant {
  const _$TerrainPresetVariantImpl(
      {required final List<TilesetVisualFrame> frames, this.weight = 1})
      : _frames = frames;

  factory _$TerrainPresetVariantImpl.fromJson(Map<String, dynamic> json) =>
      _$$TerrainPresetVariantImplFromJson(json);

  /// Au moins une frame ; rendu éditeur = première frame.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; rendu éditeur = première frame.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  @JsonKey()
  final int weight;

  @override
  String toString() {
    return 'TerrainPresetVariant(frames: $frames, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TerrainPresetVariantImpl &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_frames), weight);

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TerrainPresetVariantImplCopyWith<_$TerrainPresetVariantImpl>
      get copyWith =>
          __$$TerrainPresetVariantImplCopyWithImpl<_$TerrainPresetVariantImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TerrainPresetVariantImplToJson(
      this,
    );
  }
}

abstract class _TerrainPresetVariant implements TerrainPresetVariant {
  const factory _TerrainPresetVariant(
      {required final List<TilesetVisualFrame> frames,
      final int weight}) = _$TerrainPresetVariantImpl;

  factory _TerrainPresetVariant.fromJson(Map<String, dynamic> json) =
      _$TerrainPresetVariantImpl.fromJson;

  /// Au moins une frame ; rendu éditeur = première frame.
  @override
  List<TilesetVisualFrame> get frames;
  @override
  int get weight;

  /// Create a copy of TerrainPresetVariant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TerrainPresetVariantImplCopyWith<_$TerrainPresetVariantImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectPathPreset _$ProjectPathPresetFromJson(Map<String, dynamic> json) {
  return _ProjectPathPreset.fromJson(json);
}

/// @nodoc
mixin _$ProjectPathPreset {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  PathSurfaceKind get surfaceKind => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  List<PathPresetVariantMapping> get variants =>
      throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectPathPreset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPathPresetCopyWith<ProjectPathPreset> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPathPresetCopyWith<$Res> {
  factory $ProjectPathPresetCopyWith(
          ProjectPathPreset value, $Res Function(ProjectPathPreset) then) =
      _$ProjectPathPresetCopyWithImpl<$Res, ProjectPathPreset>;
  @useResult
  $Res call(
      {String id,
      String name,
      PathSurfaceKind surfaceKind,
      String? categoryId,
      String tilesetId,
      List<PathPresetVariantMapping> variants,
      int sortOrder});
}

/// @nodoc
class _$ProjectPathPresetCopyWithImpl<$Res, $Val extends ProjectPathPreset>
    implements $ProjectPathPresetCopyWith<$Res> {
  _$ProjectPathPresetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? surfaceKind = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      surfaceKind: null == surfaceKind
          ? _value.surfaceKind
          : surfaceKind // ignore: cast_nullable_to_non_nullable
              as PathSurfaceKind,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value.variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<PathPresetVariantMapping>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectPathPresetImplCopyWith<$Res>
    implements $ProjectPathPresetCopyWith<$Res> {
  factory _$$ProjectPathPresetImplCopyWith(_$ProjectPathPresetImpl value,
          $Res Function(_$ProjectPathPresetImpl) then) =
      __$$ProjectPathPresetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      PathSurfaceKind surfaceKind,
      String? categoryId,
      String tilesetId,
      List<PathPresetVariantMapping> variants,
      int sortOrder});
}

/// @nodoc
class __$$ProjectPathPresetImplCopyWithImpl<$Res>
    extends _$ProjectPathPresetCopyWithImpl<$Res, _$ProjectPathPresetImpl>
    implements _$$ProjectPathPresetImplCopyWith<$Res> {
  __$$ProjectPathPresetImplCopyWithImpl(_$ProjectPathPresetImpl _value,
      $Res Function(_$ProjectPathPresetImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? surfaceKind = null,
    Object? categoryId = freezed,
    Object? tilesetId = null,
    Object? variants = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectPathPresetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      surfaceKind: null == surfaceKind
          ? _value.surfaceKind
          : surfaceKind // ignore: cast_nullable_to_non_nullable
              as PathSurfaceKind,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      variants: null == variants
          ? _value._variants
          : variants // ignore: cast_nullable_to_non_nullable
              as List<PathPresetVariantMapping>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectPathPresetImpl implements _ProjectPathPreset {
  const _$ProjectPathPresetImpl(
      {required this.id,
      required this.name,
      this.surfaceKind = PathSurfaceKind.path,
      this.categoryId,
      this.tilesetId = '',
      final List<PathPresetVariantMapping> variants = const [],
      this.sortOrder = 0})
      : _variants = variants;

  factory _$ProjectPathPresetImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectPathPresetImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final PathSurfaceKind surfaceKind;
  @override
  final String? categoryId;
  @override
  @JsonKey()
  final String tilesetId;
  final List<PathPresetVariantMapping> _variants;
  @override
  @JsonKey()
  List<PathPresetVariantMapping> get variants {
    if (_variants is EqualUnmodifiableListView) return _variants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_variants);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectPathPreset(id: $id, name: $name, surfaceKind: $surfaceKind, categoryId: $categoryId, tilesetId: $tilesetId, variants: $variants, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPathPresetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.surfaceKind, surfaceKind) ||
                other.surfaceKind == surfaceKind) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            const DeepCollectionEquality().equals(other._variants, _variants) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      surfaceKind,
      categoryId,
      tilesetId,
      const DeepCollectionEquality().hash(_variants),
      sortOrder);

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPathPresetImplCopyWith<_$ProjectPathPresetImpl> get copyWith =>
      __$$ProjectPathPresetImplCopyWithImpl<_$ProjectPathPresetImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectPathPresetImplToJson(
      this,
    );
  }
}

abstract class _ProjectPathPreset implements ProjectPathPreset {
  const factory _ProjectPathPreset(
      {required final String id,
      required final String name,
      final PathSurfaceKind surfaceKind,
      final String? categoryId,
      final String tilesetId,
      final List<PathPresetVariantMapping> variants,
      final int sortOrder}) = _$ProjectPathPresetImpl;

  factory _ProjectPathPreset.fromJson(Map<String, dynamic> json) =
      _$ProjectPathPresetImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  PathSurfaceKind get surfaceKind;
  @override
  String? get categoryId;
  @override
  String get tilesetId;
  @override
  List<PathPresetVariantMapping> get variants;
  @override
  int get sortOrder;

  /// Create a copy of ProjectPathPreset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPathPresetImplCopyWith<_$ProjectPathPresetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PathPresetVariantMapping _$PathPresetVariantMappingFromJson(
    Map<String, dynamic> json) {
  return _PathPresetVariantMapping.fromJson(json);
}

/// @nodoc
mixin _$PathPresetVariantMapping {
  TerrainPathVariant get variant => throw _privateConstructorUsedError;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  List<TilesetVisualFrame> get frames => throw _privateConstructorUsedError;

  /// Serializes this PathPresetVariantMapping to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PathPresetVariantMappingCopyWith<PathPresetVariantMapping> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PathPresetVariantMappingCopyWith<$Res> {
  factory $PathPresetVariantMappingCopyWith(PathPresetVariantMapping value,
          $Res Function(PathPresetVariantMapping) then) =
      _$PathPresetVariantMappingCopyWithImpl<$Res, PathPresetVariantMapping>;
  @useResult
  $Res call({TerrainPathVariant variant, List<TilesetVisualFrame> frames});
}

/// @nodoc
class _$PathPresetVariantMappingCopyWithImpl<$Res,
        $Val extends PathPresetVariantMapping>
    implements $PathPresetVariantMappingCopyWith<$Res> {
  _$PathPresetVariantMappingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? variant = null,
    Object? frames = null,
  }) {
    return _then(_value.copyWith(
      variant: null == variant
          ? _value.variant
          : variant // ignore: cast_nullable_to_non_nullable
              as TerrainPathVariant,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PathPresetVariantMappingImplCopyWith<$Res>
    implements $PathPresetVariantMappingCopyWith<$Res> {
  factory _$$PathPresetVariantMappingImplCopyWith(
          _$PathPresetVariantMappingImpl value,
          $Res Function(_$PathPresetVariantMappingImpl) then) =
      __$$PathPresetVariantMappingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TerrainPathVariant variant, List<TilesetVisualFrame> frames});
}

/// @nodoc
class __$$PathPresetVariantMappingImplCopyWithImpl<$Res>
    extends _$PathPresetVariantMappingCopyWithImpl<$Res,
        _$PathPresetVariantMappingImpl>
    implements _$$PathPresetVariantMappingImplCopyWith<$Res> {
  __$$PathPresetVariantMappingImplCopyWithImpl(
      _$PathPresetVariantMappingImpl _value,
      $Res Function(_$PathPresetVariantMappingImpl) _then)
      : super(_value, _then);

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? variant = null,
    Object? frames = null,
  }) {
    return _then(_$PathPresetVariantMappingImpl(
      variant: null == variant
          ? _value.variant
          : variant // ignore: cast_nullable_to_non_nullable
              as TerrainPathVariant,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<TilesetVisualFrame>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PathPresetVariantMappingImpl implements _PathPresetVariantMapping {
  const _$PathPresetVariantMappingImpl(
      {required this.variant, required final List<TilesetVisualFrame> frames})
      : _frames = frames;

  factory _$PathPresetVariantMappingImpl.fromJson(Map<String, dynamic> json) =>
      _$$PathPresetVariantMappingImplFromJson(json);

  @override
  final TerrainPathVariant variant;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  final List<TilesetVisualFrame> _frames;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  @override
  List<TilesetVisualFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  String toString() {
    return 'PathPresetVariantMapping(variant: $variant, frames: $frames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PathPresetVariantMappingImpl &&
            (identical(other.variant, variant) || other.variant == variant) &&
            const DeepCollectionEquality().equals(other._frames, _frames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, variant, const DeepCollectionEquality().hash(_frames));

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PathPresetVariantMappingImplCopyWith<_$PathPresetVariantMappingImpl>
      get copyWith => __$$PathPresetVariantMappingImplCopyWithImpl<
          _$PathPresetVariantMappingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PathPresetVariantMappingImplToJson(
      this,
    );
  }
}

abstract class _PathPresetVariantMapping implements PathPresetVariantMapping {
  const factory _PathPresetVariantMapping(
          {required final TerrainPathVariant variant,
          required final List<TilesetVisualFrame> frames}) =
      _$PathPresetVariantMappingImpl;

  factory _PathPresetVariantMapping.fromJson(Map<String, dynamic> json) =
      _$PathPresetVariantMappingImpl.fromJson;

  @override
  TerrainPathVariant get variant;

  /// Au moins une frame ; rendu éditeur / autotile = première frame.
  @override
  List<TilesetVisualFrame> get frames;

  /// Create a copy of PathPresetVariantMapping
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PathPresetVariantMappingImplCopyWith<_$PathPresetVariantMappingImpl>
      get copyWith => throw _privateConstructorUsedError;
}

PathAnimationTriggerRule _$PathAnimationTriggerRuleFromJson(
    Map<String, dynamic> json) {
  return _PathAnimationTriggerRule.fromJson(json);
}

/// @nodoc
mixin _$PathAnimationTriggerRule {
  String get id => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;
  PathAnimationTriggerType get trigger => throw _privateConstructorUsedError;
  PathAnimationPlaybackMode get mode => throw _privateConstructorUsedError;
  PathAnimationActivationScope get scope => throw _privateConstructorUsedError;

  /// Serializes this PathAnimationTriggerRule to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PathAnimationTriggerRuleCopyWith<PathAnimationTriggerRule> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PathAnimationTriggerRuleCopyWith<$Res> {
  factory $PathAnimationTriggerRuleCopyWith(PathAnimationTriggerRule value,
          $Res Function(PathAnimationTriggerRule) then) =
      _$PathAnimationTriggerRuleCopyWithImpl<$Res, PathAnimationTriggerRule>;
  @useResult
  $Res call(
      {String id,
      bool enabled,
      PathAnimationTriggerType trigger,
      PathAnimationPlaybackMode mode,
      PathAnimationActivationScope scope});
}

/// @nodoc
class _$PathAnimationTriggerRuleCopyWithImpl<$Res,
        $Val extends PathAnimationTriggerRule>
    implements $PathAnimationTriggerRuleCopyWith<$Res> {
  _$PathAnimationTriggerRuleCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? enabled = null,
    Object? trigger = null,
    Object? mode = null,
    Object? scope = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as PathAnimationTriggerType,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as PathAnimationPlaybackMode,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as PathAnimationActivationScope,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PathAnimationTriggerRuleImplCopyWith<$Res>
    implements $PathAnimationTriggerRuleCopyWith<$Res> {
  factory _$$PathAnimationTriggerRuleImplCopyWith(
          _$PathAnimationTriggerRuleImpl value,
          $Res Function(_$PathAnimationTriggerRuleImpl) then) =
      __$$PathAnimationTriggerRuleImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      bool enabled,
      PathAnimationTriggerType trigger,
      PathAnimationPlaybackMode mode,
      PathAnimationActivationScope scope});
}

/// @nodoc
class __$$PathAnimationTriggerRuleImplCopyWithImpl<$Res>
    extends _$PathAnimationTriggerRuleCopyWithImpl<$Res,
        _$PathAnimationTriggerRuleImpl>
    implements _$$PathAnimationTriggerRuleImplCopyWith<$Res> {
  __$$PathAnimationTriggerRuleImplCopyWithImpl(
      _$PathAnimationTriggerRuleImpl _value,
      $Res Function(_$PathAnimationTriggerRuleImpl) _then)
      : super(_value, _then);

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? enabled = null,
    Object? trigger = null,
    Object? mode = null,
    Object? scope = null,
  }) {
    return _then(_$PathAnimationTriggerRuleImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      trigger: null == trigger
          ? _value.trigger
          : trigger // ignore: cast_nullable_to_non_nullable
              as PathAnimationTriggerType,
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as PathAnimationPlaybackMode,
      scope: null == scope
          ? _value.scope
          : scope // ignore: cast_nullable_to_non_nullable
              as PathAnimationActivationScope,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$PathAnimationTriggerRuleImpl implements _PathAnimationTriggerRule {
  const _$PathAnimationTriggerRuleImpl(
      {this.id = '',
      this.enabled = true,
      this.trigger = PathAnimationTriggerType.onStep,
      this.mode = PathAnimationPlaybackMode.restartOnTrigger,
      this.scope = PathAnimationActivationScope.wholeLayer});

  factory _$PathAnimationTriggerRuleImpl.fromJson(Map<String, dynamic> json) =>
      _$$PathAnimationTriggerRuleImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final PathAnimationTriggerType trigger;
  @override
  @JsonKey()
  final PathAnimationPlaybackMode mode;
  @override
  @JsonKey()
  final PathAnimationActivationScope scope;

  @override
  String toString() {
    return 'PathAnimationTriggerRule(id: $id, enabled: $enabled, trigger: $trigger, mode: $mode, scope: $scope)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PathAnimationTriggerRuleImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.trigger, trigger) || other.trigger == trigger) &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.scope, scope) || other.scope == scope));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, enabled, trigger, mode, scope);

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PathAnimationTriggerRuleImplCopyWith<_$PathAnimationTriggerRuleImpl>
      get copyWith => __$$PathAnimationTriggerRuleImplCopyWithImpl<
          _$PathAnimationTriggerRuleImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PathAnimationTriggerRuleImplToJson(
      this,
    );
  }
}

abstract class _PathAnimationTriggerRule implements PathAnimationTriggerRule {
  const factory _PathAnimationTriggerRule(
          {final String id,
          final bool enabled,
          final PathAnimationTriggerType trigger,
          final PathAnimationPlaybackMode mode,
          final PathAnimationActivationScope scope}) =
      _$PathAnimationTriggerRuleImpl;

  factory _PathAnimationTriggerRule.fromJson(Map<String, dynamic> json) =
      _$PathAnimationTriggerRuleImpl.fromJson;

  @override
  String get id;
  @override
  bool get enabled;
  @override
  PathAnimationTriggerType get trigger;
  @override
  PathAnimationPlaybackMode get mode;
  @override
  PathAnimationActivationScope get scope;

  /// Create a copy of PathAnimationTriggerRule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PathAnimationTriggerRuleImplCopyWith<_$PathAnimationTriggerRuleImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectPresetCategory _$ProjectPresetCategoryFromJson(
    Map<String, dynamic> json) {
  return _ProjectPresetCategory.fromJson(json);
}

/// @nodoc
mixin _$ProjectPresetCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get parentCategoryId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectPresetCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectPresetCategoryCopyWith<ProjectPresetCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectPresetCategoryCopyWith<$Res> {
  factory $ProjectPresetCategoryCopyWith(ProjectPresetCategory value,
          $Res Function(ProjectPresetCategory) then) =
      _$ProjectPresetCategoryCopyWithImpl<$Res, ProjectPresetCategory>;
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class _$ProjectPresetCategoryCopyWithImpl<$Res,
        $Val extends ProjectPresetCategory>
    implements $ProjectPresetCategoryCopyWith<$Res> {
  _$ProjectPresetCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentCategoryId: freezed == parentCategoryId
          ? _value.parentCategoryId
          : parentCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectPresetCategoryImplCopyWith<$Res>
    implements $ProjectPresetCategoryCopyWith<$Res> {
  factory _$$ProjectPresetCategoryImplCopyWith(
          _$ProjectPresetCategoryImpl value,
          $Res Function(_$ProjectPresetCategoryImpl) then) =
      __$$ProjectPresetCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? parentCategoryId, int sortOrder});
}

/// @nodoc
class __$$ProjectPresetCategoryImplCopyWithImpl<$Res>
    extends _$ProjectPresetCategoryCopyWithImpl<$Res,
        _$ProjectPresetCategoryImpl>
    implements _$$ProjectPresetCategoryImplCopyWith<$Res> {
  __$$ProjectPresetCategoryImplCopyWithImpl(_$ProjectPresetCategoryImpl _value,
      $Res Function(_$ProjectPresetCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentCategoryId = freezed,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectPresetCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentCategoryId: freezed == parentCategoryId
          ? _value.parentCategoryId
          : parentCategoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectPresetCategoryImpl implements _ProjectPresetCategory {
  const _$ProjectPresetCategoryImpl(
      {required this.id,
      required this.name,
      this.parentCategoryId,
      this.sortOrder = 0});

  factory _$ProjectPresetCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectPresetCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? parentCategoryId;
  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectPresetCategory(id: $id, name: $name, parentCategoryId: $parentCategoryId, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectPresetCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentCategoryId, parentCategoryId) ||
                other.parentCategoryId == parentCategoryId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, parentCategoryId, sortOrder);

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectPresetCategoryImplCopyWith<_$ProjectPresetCategoryImpl>
      get copyWith => __$$ProjectPresetCategoryImplCopyWithImpl<
          _$ProjectPresetCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectPresetCategoryImplToJson(
      this,
    );
  }
}

abstract class _ProjectPresetCategory implements ProjectPresetCategory {
  const factory _ProjectPresetCategory(
      {required final String id,
      required final String name,
      final String? parentCategoryId,
      final int sortOrder}) = _$ProjectPresetCategoryImpl;

  factory _ProjectPresetCategory.fromJson(Map<String, dynamic> json) =
      _$ProjectPresetCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get parentCategoryId;
  @override
  int get sortOrder;

  /// Create a copy of ProjectPresetCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectPresetCategoryImplCopyWith<_$ProjectPresetCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectEncounterEntry _$ProjectEncounterEntryFromJson(
    Map<String, dynamic> json) {
  return _ProjectEncounterEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectEncounterEntry {
  /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
  String get speciesId => throw _privateConstructorUsedError;
  int get minLevel => throw _privateConstructorUsedError;
  int get maxLevel => throw _privateConstructorUsedError;

  /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
  int get weight => throw _privateConstructorUsedError;

  /// Serializes this ProjectEncounterEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectEncounterEntryCopyWith<ProjectEncounterEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectEncounterEntryCopyWith<$Res> {
  factory $ProjectEncounterEntryCopyWith(ProjectEncounterEntry value,
          $Res Function(ProjectEncounterEntry) then) =
      _$ProjectEncounterEntryCopyWithImpl<$Res, ProjectEncounterEntry>;
  @useResult
  $Res call({String speciesId, int minLevel, int maxLevel, int weight});
}

/// @nodoc
class _$ProjectEncounterEntryCopyWithImpl<$Res,
        $Val extends ProjectEncounterEntry>
    implements $ProjectEncounterEntryCopyWith<$Res> {
  _$ProjectEncounterEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? minLevel = null,
    Object? maxLevel = null,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      minLevel: null == minLevel
          ? _value.minLevel
          : minLevel // ignore: cast_nullable_to_non_nullable
              as int,
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectEncounterEntryImplCopyWith<$Res>
    implements $ProjectEncounterEntryCopyWith<$Res> {
  factory _$$ProjectEncounterEntryImplCopyWith(
          _$ProjectEncounterEntryImpl value,
          $Res Function(_$ProjectEncounterEntryImpl) then) =
      __$$ProjectEncounterEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String speciesId, int minLevel, int maxLevel, int weight});
}

/// @nodoc
class __$$ProjectEncounterEntryImplCopyWithImpl<$Res>
    extends _$ProjectEncounterEntryCopyWithImpl<$Res,
        _$ProjectEncounterEntryImpl>
    implements _$$ProjectEncounterEntryImplCopyWith<$Res> {
  __$$ProjectEncounterEntryImplCopyWithImpl(_$ProjectEncounterEntryImpl _value,
      $Res Function(_$ProjectEncounterEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? speciesId = null,
    Object? minLevel = null,
    Object? maxLevel = null,
    Object? weight = null,
  }) {
    return _then(_$ProjectEncounterEntryImpl(
      speciesId: null == speciesId
          ? _value.speciesId
          : speciesId // ignore: cast_nullable_to_non_nullable
              as String,
      minLevel: null == minLevel
          ? _value.minLevel
          : minLevel // ignore: cast_nullable_to_non_nullable
              as int,
      maxLevel: null == maxLevel
          ? _value.maxLevel
          : maxLevel // ignore: cast_nullable_to_non_nullable
              as int,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectEncounterEntryImpl implements _ProjectEncounterEntry {
  const _$ProjectEncounterEntryImpl(
      {required this.speciesId,
      required this.minLevel,
      required this.maxLevel,
      this.weight = 1});

  factory _$ProjectEncounterEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectEncounterEntryImplFromJson(json);

  /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
  @override
  final String speciesId;
  @override
  final int minLevel;
  @override
  final int maxLevel;

  /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
  @override
  @JsonKey()
  final int weight;

  @override
  String toString() {
    return 'ProjectEncounterEntry(speciesId: $speciesId, minLevel: $minLevel, maxLevel: $maxLevel, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectEncounterEntryImpl &&
            (identical(other.speciesId, speciesId) ||
                other.speciesId == speciesId) &&
            (identical(other.minLevel, minLevel) ||
                other.minLevel == minLevel) &&
            (identical(other.maxLevel, maxLevel) ||
                other.maxLevel == maxLevel) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, speciesId, minLevel, maxLevel, weight);

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectEncounterEntryImplCopyWith<_$ProjectEncounterEntryImpl>
      get copyWith => __$$ProjectEncounterEntryImplCopyWithImpl<
          _$ProjectEncounterEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectEncounterEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectEncounterEntry implements ProjectEncounterEntry {
  const factory _ProjectEncounterEntry(
      {required final String speciesId,
      required final int minLevel,
      required final int maxLevel,
      final int weight}) = _$ProjectEncounterEntryImpl;

  factory _ProjectEncounterEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectEncounterEntryImpl.fromJson;

  /// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
  @override
  String get speciesId;
  @override
  int get minLevel;
  @override
  int get maxLevel;

  /// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
  @override
  int get weight;

  /// Create a copy of ProjectEncounterEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectEncounterEntryImplCopyWith<_$ProjectEncounterEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectEncounterTable _$ProjectEncounterTableFromJson(
    Map<String, dynamic> json) {
  return _ProjectEncounterTable.fromJson(json);
}

/// @nodoc
mixin _$ProjectEncounterTable {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  EncounterKind get encounterKind => throw _privateConstructorUsedError;
  List<ProjectEncounterEntry> get entries => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this ProjectEncounterTable to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectEncounterTableCopyWith<ProjectEncounterTable> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectEncounterTableCopyWith<$Res> {
  factory $ProjectEncounterTableCopyWith(ProjectEncounterTable value,
          $Res Function(ProjectEncounterTable) then) =
      _$ProjectEncounterTableCopyWithImpl<$Res, ProjectEncounterTable>;
  @useResult
  $Res call(
      {String id,
      String name,
      EncounterKind encounterKind,
      List<ProjectEncounterEntry> entries,
      List<String> tags});
}

/// @nodoc
class _$ProjectEncounterTableCopyWithImpl<$Res,
        $Val extends ProjectEncounterTable>
    implements $ProjectEncounterTableCopyWith<$Res> {
  _$ProjectEncounterTableCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? encounterKind = null,
    Object? entries = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
      entries: null == entries
          ? _value.entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterEntry>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectEncounterTableImplCopyWith<$Res>
    implements $ProjectEncounterTableCopyWith<$Res> {
  factory _$$ProjectEncounterTableImplCopyWith(
          _$ProjectEncounterTableImpl value,
          $Res Function(_$ProjectEncounterTableImpl) then) =
      __$$ProjectEncounterTableImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      EncounterKind encounterKind,
      List<ProjectEncounterEntry> entries,
      List<String> tags});
}

/// @nodoc
class __$$ProjectEncounterTableImplCopyWithImpl<$Res>
    extends _$ProjectEncounterTableCopyWithImpl<$Res,
        _$ProjectEncounterTableImpl>
    implements _$$ProjectEncounterTableImplCopyWith<$Res> {
  __$$ProjectEncounterTableImplCopyWithImpl(_$ProjectEncounterTableImpl _value,
      $Res Function(_$ProjectEncounterTableImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? encounterKind = null,
    Object? entries = null,
    Object? tags = null,
  }) {
    return _then(_$ProjectEncounterTableImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      encounterKind: null == encounterKind
          ? _value.encounterKind
          : encounterKind // ignore: cast_nullable_to_non_nullable
              as EncounterKind,
      entries: null == entries
          ? _value._entries
          : entries // ignore: cast_nullable_to_non_nullable
              as List<ProjectEncounterEntry>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectEncounterTableImpl implements _ProjectEncounterTable {
  const _$ProjectEncounterTableImpl(
      {required this.id,
      required this.name,
      required this.encounterKind,
      final List<ProjectEncounterEntry> entries = const [],
      final List<String> tags = const []})
      : _entries = entries,
        _tags = tags;

  factory _$ProjectEncounterTableImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectEncounterTableImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final EncounterKind encounterKind;
  final List<ProjectEncounterEntry> _entries;
  @override
  @JsonKey()
  List<ProjectEncounterEntry> get entries {
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_entries);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'ProjectEncounterTable(id: $id, name: $name, encounterKind: $encounterKind, entries: $entries, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectEncounterTableImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.encounterKind, encounterKind) ||
                other.encounterKind == encounterKind) &&
            const DeepCollectionEquality().equals(other._entries, _entries) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      encounterKind,
      const DeepCollectionEquality().hash(_entries),
      const DeepCollectionEquality().hash(_tags));

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectEncounterTableImplCopyWith<_$ProjectEncounterTableImpl>
      get copyWith => __$$ProjectEncounterTableImplCopyWithImpl<
          _$ProjectEncounterTableImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectEncounterTableImplToJson(
      this,
    );
  }
}

abstract class _ProjectEncounterTable implements ProjectEncounterTable {
  const factory _ProjectEncounterTable(
      {required final String id,
      required final String name,
      required final EncounterKind encounterKind,
      final List<ProjectEncounterEntry> entries,
      final List<String> tags}) = _$ProjectEncounterTableImpl;

  factory _ProjectEncounterTable.fromJson(Map<String, dynamic> json) =
      _$ProjectEncounterTableImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  EncounterKind get encounterKind;
  @override
  List<ProjectEncounterEntry> get entries;
  @override
  List<String> get tags;

  /// Create a copy of ProjectEncounterTable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectEncounterTableImplCopyWith<_$ProjectEncounterTableImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ProjectScriptEntry _$ProjectScriptEntryFromJson(Map<String, dynamic> json) {
  return _ProjectScriptEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectScriptEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  ScriptAsset get asset => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this ProjectScriptEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectScriptEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectScriptEntryCopyWith<ProjectScriptEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectScriptEntryCopyWith<$Res> {
  factory $ProjectScriptEntryCopyWith(
          ProjectScriptEntry value, $Res Function(ProjectScriptEntry) then) =
      _$ProjectScriptEntryCopyWithImpl<$Res, ProjectScriptEntry>;
  @useResult
  $Res call({String id, String name, ScriptAsset asset, List<String> tags});

  $ScriptAssetCopyWith<$Res> get asset;
}

/// @nodoc
class _$ProjectScriptEntryCopyWithImpl<$Res, $Val extends ProjectScriptEntry>
    implements $ProjectScriptEntryCopyWith<$Res> {
  _$ProjectScriptEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectScriptEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? asset = null,
    Object? tags = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      asset: null == asset
          ? _value.asset
          : asset // ignore: cast_nullable_to_non_nullable
              as ScriptAsset,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of ProjectScriptEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScriptAssetCopyWith<$Res> get asset {
    return $ScriptAssetCopyWith<$Res>(_value.asset, (value) {
      return _then(_value.copyWith(asset: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectScriptEntryImplCopyWith<$Res>
    implements $ProjectScriptEntryCopyWith<$Res> {
  factory _$$ProjectScriptEntryImplCopyWith(_$ProjectScriptEntryImpl value,
          $Res Function(_$ProjectScriptEntryImpl) then) =
      __$$ProjectScriptEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, ScriptAsset asset, List<String> tags});

  @override
  $ScriptAssetCopyWith<$Res> get asset;
}

/// @nodoc
class __$$ProjectScriptEntryImplCopyWithImpl<$Res>
    extends _$ProjectScriptEntryCopyWithImpl<$Res, _$ProjectScriptEntryImpl>
    implements _$$ProjectScriptEntryImplCopyWith<$Res> {
  __$$ProjectScriptEntryImplCopyWithImpl(_$ProjectScriptEntryImpl _value,
      $Res Function(_$ProjectScriptEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectScriptEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? asset = null,
    Object? tags = null,
  }) {
    return _then(_$ProjectScriptEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      asset: null == asset
          ? _value.asset
          : asset // ignore: cast_nullable_to_non_nullable
              as ScriptAsset,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectScriptEntryImpl implements _ProjectScriptEntry {
  const _$ProjectScriptEntryImpl(
      {required this.id,
      required this.name,
      required this.asset,
      final List<String> tags = const []})
      : _tags = tags;

  factory _$ProjectScriptEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectScriptEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final ScriptAsset asset;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'ProjectScriptEntry(id: $id, name: $name, asset: $asset, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectScriptEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.asset, asset) || other.asset == asset) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, asset, const DeepCollectionEquality().hash(_tags));

  /// Create a copy of ProjectScriptEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectScriptEntryImplCopyWith<_$ProjectScriptEntryImpl> get copyWith =>
      __$$ProjectScriptEntryImplCopyWithImpl<_$ProjectScriptEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectScriptEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectScriptEntry implements ProjectScriptEntry {
  const factory _ProjectScriptEntry(
      {required final String id,
      required final String name,
      required final ScriptAsset asset,
      final List<String> tags}) = _$ProjectScriptEntryImpl;

  factory _ProjectScriptEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectScriptEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  ScriptAsset get asset;
  @override
  List<String> get tags;

  /// Create a copy of ProjectScriptEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectScriptEntryImplCopyWith<_$ProjectScriptEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectCharacterEntry _$ProjectCharacterEntryFromJson(
    Map<String, dynamic> json) {
  return _ProjectCharacterEntry.fromJson(json);
}

/// @nodoc
mixin _$ProjectCharacterEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get tilesetId => throw _privateConstructorUsedError;
  int get frameWidth => throw _privateConstructorUsedError;
  int get frameHeight => throw _privateConstructorUsedError;
  List<CharacterAnimation> get animations => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ProjectCharacterEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCharacterEntryCopyWith<ProjectCharacterEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCharacterEntryCopyWith<$Res> {
  factory $ProjectCharacterEntryCopyWith(ProjectCharacterEntry value,
          $Res Function(ProjectCharacterEntry) then) =
      _$ProjectCharacterEntryCopyWithImpl<$Res, ProjectCharacterEntry>;
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      int frameWidth,
      int frameHeight,
      List<CharacterAnimation> animations,
      List<String> tags,
      int sortOrder});
}

/// @nodoc
class _$ProjectCharacterEntryCopyWithImpl<$Res,
        $Val extends ProjectCharacterEntry>
    implements $ProjectCharacterEntryCopyWith<$Res> {
  _$ProjectCharacterEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? frameWidth = null,
    Object? frameHeight = null,
    Object? animations = null,
    Object? tags = null,
    Object? sortOrder = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      frameWidth: null == frameWidth
          ? _value.frameWidth
          : frameWidth // ignore: cast_nullable_to_non_nullable
              as int,
      frameHeight: null == frameHeight
          ? _value.frameHeight
          : frameHeight // ignore: cast_nullable_to_non_nullable
              as int,
      animations: null == animations
          ? _value.animations
          : animations // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimation>,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectCharacterEntryImplCopyWith<$Res>
    implements $ProjectCharacterEntryCopyWith<$Res> {
  factory _$$ProjectCharacterEntryImplCopyWith(
          _$ProjectCharacterEntryImpl value,
          $Res Function(_$ProjectCharacterEntryImpl) then) =
      __$$ProjectCharacterEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String tilesetId,
      int frameWidth,
      int frameHeight,
      List<CharacterAnimation> animations,
      List<String> tags,
      int sortOrder});
}

/// @nodoc
class __$$ProjectCharacterEntryImplCopyWithImpl<$Res>
    extends _$ProjectCharacterEntryCopyWithImpl<$Res,
        _$ProjectCharacterEntryImpl>
    implements _$$ProjectCharacterEntryImplCopyWith<$Res> {
  __$$ProjectCharacterEntryImplCopyWithImpl(_$ProjectCharacterEntryImpl _value,
      $Res Function(_$ProjectCharacterEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? tilesetId = null,
    Object? frameWidth = null,
    Object? frameHeight = null,
    Object? animations = null,
    Object? tags = null,
    Object? sortOrder = null,
  }) {
    return _then(_$ProjectCharacterEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      tilesetId: null == tilesetId
          ? _value.tilesetId
          : tilesetId // ignore: cast_nullable_to_non_nullable
              as String,
      frameWidth: null == frameWidth
          ? _value.frameWidth
          : frameWidth // ignore: cast_nullable_to_non_nullable
              as int,
      frameHeight: null == frameHeight
          ? _value.frameHeight
          : frameHeight // ignore: cast_nullable_to_non_nullable
              as int,
      animations: null == animations
          ? _value._animations
          : animations // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimation>,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$ProjectCharacterEntryImpl implements _ProjectCharacterEntry {
  const _$ProjectCharacterEntryImpl(
      {required this.id,
      required this.name,
      required this.tilesetId,
      this.frameWidth = 1,
      this.frameHeight = 2,
      final List<CharacterAnimation> animations = const [],
      final List<String> tags = const [],
      this.sortOrder = 0})
      : _animations = animations,
        _tags = tags;

  factory _$ProjectCharacterEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectCharacterEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String tilesetId;
  @override
  @JsonKey()
  final int frameWidth;
  @override
  @JsonKey()
  final int frameHeight;
  final List<CharacterAnimation> _animations;
  @override
  @JsonKey()
  List<CharacterAnimation> get animations {
    if (_animations is EqualUnmodifiableListView) return _animations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_animations);
  }

  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final int sortOrder;

  @override
  String toString() {
    return 'ProjectCharacterEntry(id: $id, name: $name, tilesetId: $tilesetId, frameWidth: $frameWidth, frameHeight: $frameHeight, animations: $animations, tags: $tags, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectCharacterEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.tilesetId, tilesetId) ||
                other.tilesetId == tilesetId) &&
            (identical(other.frameWidth, frameWidth) ||
                other.frameWidth == frameWidth) &&
            (identical(other.frameHeight, frameHeight) ||
                other.frameHeight == frameHeight) &&
            const DeepCollectionEquality()
                .equals(other._animations, _animations) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      tilesetId,
      frameWidth,
      frameHeight,
      const DeepCollectionEquality().hash(_animations),
      const DeepCollectionEquality().hash(_tags),
      sortOrder);

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectCharacterEntryImplCopyWith<_$ProjectCharacterEntryImpl>
      get copyWith => __$$ProjectCharacterEntryImplCopyWithImpl<
          _$ProjectCharacterEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectCharacterEntryImplToJson(
      this,
    );
  }
}

abstract class _ProjectCharacterEntry implements ProjectCharacterEntry {
  const factory _ProjectCharacterEntry(
      {required final String id,
      required final String name,
      required final String tilesetId,
      final int frameWidth,
      final int frameHeight,
      final List<CharacterAnimation> animations,
      final List<String> tags,
      final int sortOrder}) = _$ProjectCharacterEntryImpl;

  factory _ProjectCharacterEntry.fromJson(Map<String, dynamic> json) =
      _$ProjectCharacterEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get tilesetId;
  @override
  int get frameWidth;
  @override
  int get frameHeight;
  @override
  List<CharacterAnimation> get animations;
  @override
  List<String> get tags;
  @override
  int get sortOrder;

  /// Create a copy of ProjectCharacterEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectCharacterEntryImplCopyWith<_$ProjectCharacterEntryImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CharacterAnimation _$CharacterAnimationFromJson(Map<String, dynamic> json) {
  return _CharacterAnimation.fromJson(json);
}

/// @nodoc
mixin _$CharacterAnimation {
  CharacterAnimationState get state => throw _privateConstructorUsedError;
  EntityFacing get direction => throw _privateConstructorUsedError;
  List<CharacterAnimationFrame> get frames =>
      throw _privateConstructorUsedError;

  /// Serializes this CharacterAnimation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterAnimationCopyWith<CharacterAnimation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterAnimationCopyWith<$Res> {
  factory $CharacterAnimationCopyWith(
          CharacterAnimation value, $Res Function(CharacterAnimation) then) =
      _$CharacterAnimationCopyWithImpl<$Res, CharacterAnimation>;
  @useResult
  $Res call(
      {CharacterAnimationState state,
      EntityFacing direction,
      List<CharacterAnimationFrame> frames});
}

/// @nodoc
class _$CharacterAnimationCopyWithImpl<$Res, $Val extends CharacterAnimation>
    implements $CharacterAnimationCopyWith<$Res> {
  _$CharacterAnimationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? direction = null,
    Object? frames = null,
  }) {
    return _then(_value.copyWith(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as CharacterAnimationState,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimationFrame>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CharacterAnimationImplCopyWith<$Res>
    implements $CharacterAnimationCopyWith<$Res> {
  factory _$$CharacterAnimationImplCopyWith(_$CharacterAnimationImpl value,
          $Res Function(_$CharacterAnimationImpl) then) =
      __$$CharacterAnimationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {CharacterAnimationState state,
      EntityFacing direction,
      List<CharacterAnimationFrame> frames});
}

/// @nodoc
class __$$CharacterAnimationImplCopyWithImpl<$Res>
    extends _$CharacterAnimationCopyWithImpl<$Res, _$CharacterAnimationImpl>
    implements _$$CharacterAnimationImplCopyWith<$Res> {
  __$$CharacterAnimationImplCopyWithImpl(_$CharacterAnimationImpl _value,
      $Res Function(_$CharacterAnimationImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? direction = null,
    Object? frames = null,
  }) {
    return _then(_$CharacterAnimationImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as CharacterAnimationState,
      direction: null == direction
          ? _value.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as EntityFacing,
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<CharacterAnimationFrame>,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$CharacterAnimationImpl implements _CharacterAnimation {
  const _$CharacterAnimationImpl(
      {required this.state,
      required this.direction,
      final List<CharacterAnimationFrame> frames = const []})
      : _frames = frames;

  factory _$CharacterAnimationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterAnimationImplFromJson(json);

  @override
  final CharacterAnimationState state;
  @override
  final EntityFacing direction;
  final List<CharacterAnimationFrame> _frames;
  @override
  @JsonKey()
  List<CharacterAnimationFrame> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  @override
  String toString() {
    return 'CharacterAnimation(state: $state, direction: $direction, frames: $frames)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterAnimationImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            const DeepCollectionEquality().equals(other._frames, _frames));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, direction,
      const DeepCollectionEquality().hash(_frames));

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterAnimationImplCopyWith<_$CharacterAnimationImpl> get copyWith =>
      __$$CharacterAnimationImplCopyWithImpl<_$CharacterAnimationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterAnimationImplToJson(
      this,
    );
  }
}

abstract class _CharacterAnimation implements CharacterAnimation {
  const factory _CharacterAnimation(
      {required final CharacterAnimationState state,
      required final EntityFacing direction,
      final List<CharacterAnimationFrame> frames}) = _$CharacterAnimationImpl;

  factory _CharacterAnimation.fromJson(Map<String, dynamic> json) =
      _$CharacterAnimationImpl.fromJson;

  @override
  CharacterAnimationState get state;
  @override
  EntityFacing get direction;
  @override
  List<CharacterAnimationFrame> get frames;

  /// Create a copy of CharacterAnimation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterAnimationImplCopyWith<_$CharacterAnimationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CharacterAnimationFrame _$CharacterAnimationFrameFromJson(
    Map<String, dynamic> json) {
  return _CharacterAnimationFrame.fromJson(json);
}

/// @nodoc
mixin _$CharacterAnimationFrame {
  TilesetSourceRect get source => throw _privateConstructorUsedError;
  int get durationMs => throw _privateConstructorUsedError;

  /// Serializes this CharacterAnimationFrame to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CharacterAnimationFrameCopyWith<CharacterAnimationFrame> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CharacterAnimationFrameCopyWith<$Res> {
  factory $CharacterAnimationFrameCopyWith(CharacterAnimationFrame value,
          $Res Function(CharacterAnimationFrame) then) =
      _$CharacterAnimationFrameCopyWithImpl<$Res, CharacterAnimationFrame>;
  @useResult
  $Res call({TilesetSourceRect source, int durationMs});

  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class _$CharacterAnimationFrameCopyWithImpl<$Res,
        $Val extends CharacterAnimationFrame>
    implements $CharacterAnimationFrameCopyWith<$Res> {
  _$CharacterAnimationFrameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? durationMs = null,
  }) {
    return _then(_value.copyWith(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TilesetSourceRectCopyWith<$Res> get source {
    return $TilesetSourceRectCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CharacterAnimationFrameImplCopyWith<$Res>
    implements $CharacterAnimationFrameCopyWith<$Res> {
  factory _$$CharacterAnimationFrameImplCopyWith(
          _$CharacterAnimationFrameImpl value,
          $Res Function(_$CharacterAnimationFrameImpl) then) =
      __$$CharacterAnimationFrameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({TilesetSourceRect source, int durationMs});

  @override
  $TilesetSourceRectCopyWith<$Res> get source;
}

/// @nodoc
class __$$CharacterAnimationFrameImplCopyWithImpl<$Res>
    extends _$CharacterAnimationFrameCopyWithImpl<$Res,
        _$CharacterAnimationFrameImpl>
    implements _$$CharacterAnimationFrameImplCopyWith<$Res> {
  __$$CharacterAnimationFrameImplCopyWithImpl(
      _$CharacterAnimationFrameImpl _value,
      $Res Function(_$CharacterAnimationFrameImpl) _then)
      : super(_value, _then);

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? source = null,
    Object? durationMs = null,
  }) {
    return _then(_$CharacterAnimationFrameImpl(
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as TilesetSourceRect,
      durationMs: null == durationMs
          ? _value.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$CharacterAnimationFrameImpl implements _CharacterAnimationFrame {
  const _$CharacterAnimationFrameImpl(
      {required this.source, this.durationMs = 150});

  factory _$CharacterAnimationFrameImpl.fromJson(Map<String, dynamic> json) =>
      _$$CharacterAnimationFrameImplFromJson(json);

  @override
  final TilesetSourceRect source;
  @override
  @JsonKey()
  final int durationMs;

  @override
  String toString() {
    return 'CharacterAnimationFrame(source: $source, durationMs: $durationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CharacterAnimationFrameImpl &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, source, durationMs);

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CharacterAnimationFrameImplCopyWith<_$CharacterAnimationFrameImpl>
      get copyWith => __$$CharacterAnimationFrameImplCopyWithImpl<
          _$CharacterAnimationFrameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CharacterAnimationFrameImplToJson(
      this,
    );
  }
}

abstract class _CharacterAnimationFrame implements CharacterAnimationFrame {
  const factory _CharacterAnimationFrame(
      {required final TilesetSourceRect source,
      final int durationMs}) = _$CharacterAnimationFrameImpl;

  factory _CharacterAnimationFrame.fromJson(Map<String, dynamic> json) =
      _$CharacterAnimationFrameImpl.fromJson;

  @override
  TilesetSourceRect get source;
  @override
  int get durationMs;

  /// Create a copy of CharacterAnimationFrame
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CharacterAnimationFrameImplCopyWith<_$CharacterAnimationFrameImpl>
      get copyWith => throw _privateConstructorUsedError;
}
```

### 13.5 packages/map_core/lib/src/models/project_manifest.g.dart

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectManifestImpl _$$ProjectManifestImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectManifestImpl(
      name: json['name'] as String,
      version: $enumDecodeNullable(_$ProjectVersionEnumMap, json['version']) ??
          ProjectVersion.v1,
      maps: (json['maps'] as List<dynamic>)
          .map((e) => ProjectMapEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => ProjectMapGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tilesetFolders: (json['tilesetFolders'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTilesetFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tilesets: (json['tilesets'] as List<dynamic>)
          .map((e) => ProjectTilesetEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      elementCategories: (json['elementCategories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectElementCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectElementEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      terrainCategories: (json['terrainCategories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectPresetCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pathCategories: (json['pathCategories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectPresetCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      terrainPresets: (json['terrainPresets'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTerrainPreset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      pathPresets: (json['pathPresets'] as List<dynamic>?)
              ?.map(
                  (e) => ProjectPathPreset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      encounterTables: (json['encounterTables'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectEncounterTable.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dialogueFolders: (json['dialogueFolders'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectDialogueFolder.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      dialogues: (json['dialogues'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectDialogueEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      scripts: (json['scripts'] as List<dynamic>?)
              ?.map(
                  (e) => ProjectScriptEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      scenarios: (json['scenarios'] as List<dynamic>?)
              ?.map((e) => ScenarioAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      trainers: (json['trainers'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectTrainerEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectCharacterEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      settings: json['settings'] == null
          ? const ProjectSettings()
          : ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
      pokemon: json['pokemon'] == null
          ? const ProjectPokemonConfig()
          : ProjectPokemonConfig.fromJson(
              json['pokemon'] as Map<String, dynamic>),
      globalProperties:
          json['globalProperties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ProjectManifestImplToJson(
        _$ProjectManifestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': _$ProjectVersionEnumMap[instance.version]!,
      'maps': instance.maps.map((e) => e.toJson()).toList(),
      'groups': instance.groups.map((e) => e.toJson()).toList(),
      'tilesetFolders': instance.tilesetFolders.map((e) => e.toJson()).toList(),
      'tilesets': instance.tilesets.map((e) => e.toJson()).toList(),
      'elementCategories':
          instance.elementCategories.map((e) => e.toJson()).toList(),
      'elements': instance.elements.map((e) => e.toJson()).toList(),
      'terrainCategories':
          instance.terrainCategories.map((e) => e.toJson()).toList(),
      'pathCategories': instance.pathCategories.map((e) => e.toJson()).toList(),
      'terrainPresets': instance.terrainPresets.map((e) => e.toJson()).toList(),
      'pathPresets': instance.pathPresets.map((e) => e.toJson()).toList(),
      'encounterTables':
          instance.encounterTables.map((e) => e.toJson()).toList(),
      'dialogueFolders':
          instance.dialogueFolders.map((e) => e.toJson()).toList(),
      'dialogues': instance.dialogues.map((e) => e.toJson()).toList(),
      'scripts': instance.scripts.map((e) => e.toJson()).toList(),
      'scenarios': instance.scenarios.map((e) => e.toJson()).toList(),
      'trainers': instance.trainers.map((e) => e.toJson()).toList(),
      'characters': instance.characters.map((e) => e.toJson()).toList(),
      'settings': instance.settings.toJson(),
      'pokemon': instance.pokemon.toJson(),
      'globalProperties': instance.globalProperties,
    };

const _$ProjectVersionEnumMap = {
  ProjectVersion.v1: 'v1',
};

_$ProjectPokemonConfigImpl _$$ProjectPokemonConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectPokemonConfigImpl(
      enabled: json['enabled'] as bool? ?? true,
      dataRoot: json['dataRoot'] as String? ?? 'data/pokemon',
      speciesDir: json['speciesDir'] as String? ?? 'data/pokemon/species',
      learnsetsDir: json['learnsetsDir'] as String? ?? 'data/pokemon/learnsets',
      evolutionsDir:
          json['evolutionsDir'] as String? ?? 'data/pokemon/evolutions',
      mediaDir: json['mediaDir'] as String? ?? 'data/pokemon/sprite_sets',
      catalogFiles: (json['catalogFiles'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          _defaultPokemonCatalogFiles,
    );

Map<String, dynamic> _$$ProjectPokemonConfigImplToJson(
        _$ProjectPokemonConfigImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'dataRoot': instance.dataRoot,
      'speciesDir': instance.speciesDir,
      'learnsetsDir': instance.learnsetsDir,
      'evolutionsDir': instance.evolutionsDir,
      'mediaDir': instance.mediaDir,
      'catalogFiles': instance.catalogFiles,
    };

_$ProjectSettingsImpl _$$ProjectSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectSettingsImpl(
      tileWidth: (json['tileWidth'] as num?)?.toInt() ?? 16,
      tileHeight: (json['tileHeight'] as num?)?.toInt() ?? 16,
      displayScale: (json['displayScale'] as num?)?.toDouble() ?? 2.0,
      defaultMapWidth: (json['defaultMapWidth'] as num?)?.toInt() ?? 20,
      defaultMapHeight: (json['defaultMapHeight'] as num?)?.toInt() ?? 15,
      defaultPlayerCharacterId:
          _readDefaultPlayerCharacterId(json, 'defaultPlayerCharacterId')
              as String?,
      mistralApiKey: json['mistralApiKey'] as String?,
    );

Map<String, dynamic> _$$ProjectSettingsImplToJson(
        _$ProjectSettingsImpl instance) =>
    <String, dynamic>{
      'tileWidth': instance.tileWidth,
      'tileHeight': instance.tileHeight,
      'displayScale': instance.displayScale,
      'defaultMapWidth': instance.defaultMapWidth,
      'defaultMapHeight': instance.defaultMapHeight,
      'defaultPlayerCharacterId': instance.defaultPlayerCharacterId,
      if (instance.mistralApiKey case final value?) 'mistralApiKey': value,
    };

_$ProjectMapGroupImpl _$$ProjectMapGroupImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectMapGroupImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$MapGroupTypeEnumMap, json['type']),
      parentGroupId: json['parentGroupId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ProjectMapGroupImplToJson(
        _$ProjectMapGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$MapGroupTypeEnumMap[instance.type]!,
      'parentGroupId': instance.parentGroupId,
      'sortOrder': instance.sortOrder,
      'tags': instance.tags,
      'properties': instance.properties,
    };

const _$MapGroupTypeEnumMap = {
  MapGroupType.city: 'city',
  MapGroupType.village: 'village',
  MapGroupType.route: 'route',
  MapGroupType.dungeon: 'dungeon',
  MapGroupType.cave: 'cave',
  MapGroupType.forest: 'forest',
  MapGroupType.tower: 'tower',
  MapGroupType.facility: 'facility',
  MapGroupType.special: 'special',
};

_$ProjectMapEntryImpl _$$ProjectMapEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectMapEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      groupId: json['groupId'] as String?,
      role: $enumDecodeNullable(_$MapRoleEnumMap, json['role']) ??
          MapRole.exterior,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectMapEntryImplToJson(
        _$ProjectMapEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'groupId': instance.groupId,
      'role': _$MapRoleEnumMap[instance.role]!,
      'sortOrder': instance.sortOrder,
    };

const _$MapRoleEnumMap = {
  MapRole.exterior: 'exterior',
  MapRole.interior: 'interior',
  MapRole.basement: 'basement',
  MapRole.upper_floor: 'upper_floor',
  MapRole.connector: 'connector',
  MapRole.gate: 'gate',
  MapRole.room: 'room',
  MapRole.section: 'section',
  MapRole.sub_area: 'sub_area',
};

_$ProjectDialogueFolderImpl _$$ProjectDialogueFolderImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectDialogueFolderImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectDialogueFolderImplToJson(
        _$ProjectDialogueFolderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentFolderId': instance.parentFolderId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectDialogueEntryImpl _$$ProjectDialogueEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectDialogueEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      description: json['description'] as String? ?? '',
      defaultStartNode: json['defaultStartNode'] as String?,
      folderId: json['folderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectDialogueEntryImplToJson(
        _$ProjectDialogueEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'tags': instance.tags,
      'description': instance.description,
      'defaultStartNode': instance.defaultStartNode,
      'folderId': instance.folderId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectTilesetFolderImpl _$$ProjectTilesetFolderImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTilesetFolderImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parentFolderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectTilesetFolderImplToJson(
        _$ProjectTilesetFolderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentFolderId': instance.parentFolderId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectTilesetEntryImpl _$$ProjectTilesetEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTilesetEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      relativePath: json['relativePath'] as String,
      scope: $enumDecodeNullable(_$TilesetScopeEnumMap, json['scope']) ??
          TilesetScope.global,
      groupId: json['groupId'] as String?,
      folderId: json['folderId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isWorldTileset: json['isWorldTileset'] as bool? ?? false,
      elementGroups: (json['elementGroups'] as List<dynamic>?)
              ?.map((e) =>
                  TilesetElementGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      paletteEntries: (json['paletteEntries'] as List<dynamic>?)
              ?.map((e) =>
                  TilesetPaletteEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$ProjectTilesetEntryImplToJson(
        _$ProjectTilesetEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'relativePath': instance.relativePath,
      'scope': _$TilesetScopeEnumMap[instance.scope]!,
      'groupId': instance.groupId,
      'folderId': instance.folderId,
      'sortOrder': instance.sortOrder,
      'isWorldTileset': instance.isWorldTileset,
      'elementGroups': instance.elementGroups,
      'paletteEntries': instance.paletteEntries,
    };

const _$TilesetScopeEnumMap = {
  TilesetScope.global: 'global',
  TilesetScope.group: 'group',
};

_$TilesetPaletteEntryImpl _$$TilesetPaletteEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetPaletteEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category:
          $enumDecodeNullable(_$PaletteCategoryEnumMap, json['category']) ??
              PaletteCategory.uncategorized,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedLayerId: json['recommendedLayerId'] as String?,
    );

Map<String, dynamic> _$$TilesetPaletteEntryImplToJson(
        _$TilesetPaletteEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': _$PaletteCategoryEnumMap[instance.category]!,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'recommendedLayerId': instance.recommendedLayerId,
    };

const _$PaletteCategoryEnumMap = {
  PaletteCategory.floors: 'floors',
  PaletteCategory.paths: 'paths',
  PaletteCategory.water: 'water',
  PaletteCategory.buildings: 'buildings',
  PaletteCategory.roofs: 'roofs',
  PaletteCategory.plants: 'plants',
  PaletteCategory.trees: 'trees',
  PaletteCategory.cliffs: 'cliffs',
  PaletteCategory.decorations: 'decorations',
  PaletteCategory.interiors: 'interiors',
  PaletteCategory.objects: 'objects',
  PaletteCategory.uncategorized: 'uncategorized',
};

_$TilesetSourceRectImpl _$$TilesetSourceRectImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetSourceRectImpl(
      x: (json['x'] as num).toInt(),
      y: (json['y'] as num).toInt(),
      width: (json['width'] as num?)?.toInt() ?? 1,
      height: (json['height'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$TilesetSourceRectImplToJson(
        _$TilesetSourceRectImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };

_$TilesetVisualFrameImpl _$$TilesetVisualFrameImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetVisualFrameImpl(
      tilesetId: json['tilesetId'] as String? ?? '',
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
      durationMs: (json['durationMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TilesetVisualFrameImplToJson(
        _$TilesetVisualFrameImpl instance) =>
    <String, dynamic>{
      'tilesetId': instance.tilesetId,
      'source': instance.source.toJson(),
      'durationMs': instance.durationMs,
    };

_$TilesetElementGroupImpl _$$TilesetElementGroupImplFromJson(
        Map<String, dynamic> json) =>
    _$TilesetElementGroupImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentGroupId: json['parentGroupId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$TilesetElementGroupImplToJson(
        _$TilesetElementGroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentGroupId': instance.parentGroupId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectElementCategoryImpl _$$ProjectElementCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectElementCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectElementCategoryImplToJson(
        _$ProjectElementCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentCategoryId': instance.parentCategoryId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectElementEntryImpl _$$ProjectElementEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectElementEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      tilesetId: json['tilesetId'] as String,
      categoryId: json['categoryId'] as String,
      tilesetGroupId: json['tilesetGroupId'] as String?,
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      presetKind:
          $enumDecodeNullable(_$ElementPresetKindEnumMap, json['presetKind']) ??
              ElementPresetKind.generic,
      collisionProfile: json['collisionProfile'] == null
          ? null
          : ElementCollisionProfile.fromJson(
              json['collisionProfile'] as Map<String, dynamic>),
      groupId: json['groupId'] as String?,
      recommendedLayerId: json['recommendedLayerId'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectElementEntryImplToJson(
        _$ProjectElementEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tilesetId': instance.tilesetId,
      'categoryId': instance.categoryId,
      'tilesetGroupId': instance.tilesetGroupId,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'presetKind': _$ElementPresetKindEnumMap[instance.presetKind]!,
      'collisionProfile': instance.collisionProfile?.toJson(),
      'groupId': instance.groupId,
      'recommendedLayerId': instance.recommendedLayerId,
      'tags': instance.tags,
      'sortOrder': instance.sortOrder,
    };

const _$ElementPresetKindEnumMap = {
  ElementPresetKind.generic: 'generic',
  ElementPresetKind.tree: 'tree',
  ElementPresetKind.building: 'building',
  ElementPresetKind.rock: 'rock',
  ElementPresetKind.cliff: 'cliff',
  ElementPresetKind.tallDecoration: 'tall_decoration',
};

_$ProjectTerrainPresetImpl _$$ProjectTerrainPresetImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectTerrainPresetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      terrainType: $enumDecode(_$TerrainTypeEnumMap, json['terrainType']),
      categoryId: json['categoryId'] as String?,
      tilesetId: json['tilesetId'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) =>
                  TerrainPresetVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectTerrainPresetImplToJson(
        _$ProjectTerrainPresetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'terrainType': _$TerrainTypeEnumMap[instance.terrainType]!,
      'categoryId': instance.categoryId,
      'tilesetId': instance.tilesetId,
      'variants': instance.variants,
      'sortOrder': instance.sortOrder,
    };

const _$TerrainTypeEnumMap = {
  TerrainType.none: 'none',
  TerrainType.grass: 'grass',
  TerrainType.dirt: 'dirt',
  TerrainType.sand: 'sand',
  TerrainType.rock: 'rock',
  TerrainType.stone: 'stone',
  TerrainType.indoor: 'indoor',
};

_$TerrainPresetVariantImpl _$$TerrainPresetVariantImplFromJson(
        Map<String, dynamic> json) =>
    _$TerrainPresetVariantImpl(
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$TerrainPresetVariantImplToJson(
        _$TerrainPresetVariantImpl instance) =>
    <String, dynamic>{
      'frames': instance.frames.map((e) => e.toJson()).toList(),
      'weight': instance.weight,
    };

_$ProjectPathPresetImpl _$$ProjectPathPresetImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectPathPresetImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      surfaceKind:
          $enumDecodeNullable(_$PathSurfaceKindEnumMap, json['surfaceKind']) ??
              PathSurfaceKind.path,
      categoryId: json['categoryId'] as String?,
      tilesetId: json['tilesetId'] as String? ?? '',
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) =>
                  PathPresetVariantMapping.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectPathPresetImplToJson(
        _$ProjectPathPresetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'surfaceKind': _$PathSurfaceKindEnumMap[instance.surfaceKind]!,
      'categoryId': instance.categoryId,
      'tilesetId': instance.tilesetId,
      'variants': instance.variants,
      'sortOrder': instance.sortOrder,
    };

const _$PathSurfaceKindEnumMap = {
  PathSurfaceKind.path: 'path',
  PathSurfaceKind.road: 'road',
  PathSurfaceKind.water: 'water',
  PathSurfaceKind.tallGrass: 'tall_grass',
  PathSurfaceKind.ice: 'ice',
  PathSurfaceKind.lava: 'lava',
  PathSurfaceKind.swamp: 'swamp',
  PathSurfaceKind.rails: 'rails',
  PathSurfaceKind.bridge: 'bridge',
  PathSurfaceKind.special: 'special',
  PathSurfaceKind.custom: 'custom',
};

_$PathPresetVariantMappingImpl _$$PathPresetVariantMappingImplFromJson(
        Map<String, dynamic> json) =>
    _$PathPresetVariantMappingImpl(
      variant: $enumDecode(_$TerrainPathVariantEnumMap, json['variant']),
      frames: (json['frames'] as List<dynamic>)
          .map((e) => TilesetVisualFrame.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$PathPresetVariantMappingImplToJson(
        _$PathPresetVariantMappingImpl instance) =>
    <String, dynamic>{
      'variant': _$TerrainPathVariantEnumMap[instance.variant]!,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
    };

const _$TerrainPathVariantEnumMap = {
  TerrainPathVariant.isolated: 'isolated',
  TerrainPathVariant.endNorth: 'endNorth',
  TerrainPathVariant.endEast: 'endEast',
  TerrainPathVariant.endSouth: 'endSouth',
  TerrainPathVariant.endWest: 'endWest',
  TerrainPathVariant.horizontal: 'horizontal',
  TerrainPathVariant.vertical: 'vertical',
  TerrainPathVariant.cornerNE: 'cornerNE',
  TerrainPathVariant.cornerSE: 'cornerSE',
  TerrainPathVariant.cornerSW: 'cornerSW',
  TerrainPathVariant.cornerNW: 'cornerNW',
  TerrainPathVariant.innerCornerNE: 'innerCornerNE',
  TerrainPathVariant.innerCornerSE: 'innerCornerSE',
  TerrainPathVariant.innerCornerSW: 'innerCornerSW',
  TerrainPathVariant.innerCornerNW: 'innerCornerNW',
  TerrainPathVariant.teeNorth: 'teeNorth',
  TerrainPathVariant.teeEast: 'teeEast',
  TerrainPathVariant.teeSouth: 'teeSouth',
  TerrainPathVariant.teeWest: 'teeWest',
  TerrainPathVariant.cross: 'cross',
};

_$PathAnimationTriggerRuleImpl _$$PathAnimationTriggerRuleImplFromJson(
        Map<String, dynamic> json) =>
    _$PathAnimationTriggerRuleImpl(
      id: json['id'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      trigger: $enumDecodeNullable(
              _$PathAnimationTriggerTypeEnumMap, json['trigger']) ??
          PathAnimationTriggerType.onStep,
      mode: $enumDecodeNullable(
              _$PathAnimationPlaybackModeEnumMap, json['mode']) ??
          PathAnimationPlaybackMode.restartOnTrigger,
      scope: $enumDecodeNullable(
              _$PathAnimationActivationScopeEnumMap, json['scope']) ??
          PathAnimationActivationScope.wholeLayer,
    );

Map<String, dynamic> _$$PathAnimationTriggerRuleImplToJson(
        _$PathAnimationTriggerRuleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'enabled': instance.enabled,
      'trigger': _$PathAnimationTriggerTypeEnumMap[instance.trigger]!,
      'mode': _$PathAnimationPlaybackModeEnumMap[instance.mode]!,
      'scope': _$PathAnimationActivationScopeEnumMap[instance.scope]!,
    };

const _$PathAnimationTriggerTypeEnumMap = {
  PathAnimationTriggerType.onEnter: 'on_enter',
  PathAnimationTriggerType.onStep: 'on_step',
  PathAnimationTriggerType.onNear: 'on_near',
  PathAnimationTriggerType.onAction: 'on_action',
  PathAnimationTriggerType.whileInside: 'while_inside',
  PathAnimationTriggerType.onBump: 'on_bump',
};

const _$PathAnimationPlaybackModeEnumMap = {
  PathAnimationPlaybackMode.playOnce: 'play_once',
  PathAnimationPlaybackMode.loopWhileActive: 'loop_while_active',
  PathAnimationPlaybackMode.restartOnTrigger: 'restart_on_trigger',
};

const _$PathAnimationActivationScopeEnumMap = {
  PathAnimationActivationScope.wholeLayer: 'whole_layer',
  PathAnimationActivationScope.cellOnly: 'cell_only',
};

_$ProjectPresetCategoryImpl _$$ProjectPresetCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectPresetCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentCategoryId: json['parentCategoryId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectPresetCategoryImplToJson(
        _$ProjectPresetCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentCategoryId': instance.parentCategoryId,
      'sortOrder': instance.sortOrder,
    };

_$ProjectEncounterEntryImpl _$$ProjectEncounterEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectEncounterEntryImpl(
      speciesId: json['speciesId'] as String,
      minLevel: (json['minLevel'] as num).toInt(),
      maxLevel: (json['maxLevel'] as num).toInt(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$ProjectEncounterEntryImplToJson(
        _$ProjectEncounterEntryImpl instance) =>
    <String, dynamic>{
      'speciesId': instance.speciesId,
      'minLevel': instance.minLevel,
      'maxLevel': instance.maxLevel,
      'weight': instance.weight,
    };

_$ProjectEncounterTableImpl _$$ProjectEncounterTableImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectEncounterTableImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      encounterKind: $enumDecode(_$EncounterKindEnumMap, json['encounterKind']),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectEncounterEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$ProjectEncounterTableImplToJson(
        _$ProjectEncounterTableImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'encounterKind': _$EncounterKindEnumMap[instance.encounterKind]!,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
    };

const _$EncounterKindEnumMap = {
  EncounterKind.walk: 'walk',
  EncounterKind.surf: 'surf',
  EncounterKind.headbutt: 'headbutt',
  EncounterKind.oldRod: 'old_rod',
  EncounterKind.goodRod: 'good_rod',
  EncounterKind.superRod: 'super_rod',
  EncounterKind.gift: 'gift',
  EncounterKind.special: 'special',
};

_$ProjectScriptEntryImpl _$$ProjectScriptEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectScriptEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      asset: ScriptAsset.fromJson(json['asset'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$$ProjectScriptEntryImplToJson(
        _$ProjectScriptEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'asset': instance.asset.toJson(),
      'tags': instance.tags,
    };

_$ProjectCharacterEntryImpl _$$ProjectCharacterEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectCharacterEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      tilesetId: json['tilesetId'] as String,
      frameWidth: (json['frameWidth'] as num?)?.toInt() ?? 1,
      frameHeight: (json['frameHeight'] as num?)?.toInt() ?? 2,
      animations: (json['animations'] as List<dynamic>?)
              ?.map(
                  (e) => CharacterAnimation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProjectCharacterEntryImplToJson(
        _$ProjectCharacterEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'tilesetId': instance.tilesetId,
      'frameWidth': instance.frameWidth,
      'frameHeight': instance.frameHeight,
      'animations': instance.animations.map((e) => e.toJson()).toList(),
      'tags': instance.tags,
      'sortOrder': instance.sortOrder,
    };

_$CharacterAnimationImpl _$$CharacterAnimationImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterAnimationImpl(
      state: $enumDecode(_$CharacterAnimationStateEnumMap, json['state']),
      direction: $enumDecode(_$EntityFacingEnumMap, json['direction']),
      frames: (json['frames'] as List<dynamic>?)
              ?.map((e) =>
                  CharacterAnimationFrame.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$CharacterAnimationImplToJson(
        _$CharacterAnimationImpl instance) =>
    <String, dynamic>{
      'state': _$CharacterAnimationStateEnumMap[instance.state]!,
      'direction': _$EntityFacingEnumMap[instance.direction]!,
      'frames': instance.frames.map((e) => e.toJson()).toList(),
    };

const _$CharacterAnimationStateEnumMap = {
  CharacterAnimationState.idle: 'idle',
  CharacterAnimationState.walk: 'walk',
  CharacterAnimationState.run: 'run',
};

const _$EntityFacingEnumMap = {
  EntityFacing.north: 'north',
  EntityFacing.south: 'south',
  EntityFacing.east: 'east',
  EntityFacing.west: 'west',
};

_$CharacterAnimationFrameImpl _$$CharacterAnimationFrameImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterAnimationFrameImpl(
      source:
          TilesetSourceRect.fromJson(json['source'] as Map<String, dynamic>),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 150,
    );

Map<String, dynamic> _$$CharacterAnimationFrameImplToJson(
        _$CharacterAnimationFrameImpl instance) =>
    <String, dynamic>{
      'source': instance.source.toJson(),
      'durationMs': instance.durationMs,
    };
```

### 13.6 packages/map_editor/test/project_pokemon_config_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late FileProjectRepository repository;
  late CreateProjectUseCase createProjectUseCase;
  late LoadProjectUseCase loadProjectUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('project_pokemon_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    repository = FileProjectRepository();
    createProjectUseCase = CreateProjectUseCase(
      repository,
      const FileProjectWorkspaceFactory(),
    );
    loadProjectUseCase = LoadProjectUseCase(repository);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('Project pokemon config', () {
    test('loads an older project without pokemon config and applies defaults',
        () async {
      await createProjectUseCase.execute('Legacy Pokemon Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final json = jsonDecode(await projectFile.readAsString())
          as Map<String, dynamic>;
      json.remove('pokemon');
      await projectFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      final loaded = await loadProjectUseCase.execute(projectFile.path);

      expect(loaded.pokemon, const ProjectPokemonConfig());
    });

    test('creates a new project with the default lightweight pokemon config',
        () async {
      final manifest = await createProjectUseCase.execute(
        'Pokemon Config Project',
        tempProjectRoot.path,
      );

      expect(manifest.pokemon, const ProjectPokemonConfig());

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final json = jsonDecode(await projectFile.readAsString())
          as Map<String, dynamic>;
      final pokemon = json['pokemon'] as Map<String, dynamic>;

      expect(
        pokemon.keys.toSet(),
        equals(<String>{
          'enabled',
          'dataRoot',
          'speciesDir',
          'learnsetsDir',
          'evolutionsDir',
          'mediaDir',
          'catalogFiles',
        }),
      );
      expect(pokemon['enabled'], isTrue);
      expect(pokemon['dataRoot'], 'data/pokemon');
      expect(pokemon['speciesDir'], 'data/pokemon/species');
      expect(pokemon['learnsetsDir'], 'data/pokemon/learnsets');
      expect(pokemon['evolutionsDir'], 'data/pokemon/evolutions');
      expect(pokemon['mediaDir'], 'data/pokemon/sprite_sets');
      expect(
        pokemon['catalogFiles'],
        <String, Object?>{
          'moves': 'data/pokemon/catalogs/moves.json',
          'abilities': 'data/pokemon/catalogs/abilities.json',
          'items': 'data/pokemon/catalogs/items.json',
          'types': 'data/pokemon/catalogs/types.json',
          'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
          'natures': 'data/pokemon/catalogs/natures.json',
        },
      );

      expect(pokemon.containsKey('species'), isFalse);
      expect(pokemon.containsKey('learnsets'), isFalse);
      expect(pokemon.containsKey('evolutions'), isFalse);
      expect(pokemon.containsKey('entries'), isFalse);
    });

    test('round-trips pokemon config through save and load without corruption',
        () async {
      await createProjectUseCase.execute('Pokemon Roundtrip Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final before = await projectFile.readAsString();

      final loaded = await loadProjectUseCase.execute(projectFile.path);
      await repository.saveProject(loaded, projectFile.path);

      final after = await projectFile.readAsString();

      expect(after, before);
    });

    test('loads project config without reading pokemon data files', () async {
      await createProjectUseCase.execute('Pokemon Lazy Config Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      final loaded = await loadProjectUseCase.execute(projectFile.path);

      expect(loaded.pokemon, const ProjectPokemonConfig());
      expect(
        Directory(p.join(tempProjectRoot.path, 'data', 'pokemon')).existsSync(),
        isFalse,
      );
      expect(
        Directory(p.join(tempProjectRoot.path, 'assets', 'pokemon')).existsSync(),
        isFalse,
      );
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await createProjectUseCase.execute('Pokemon Root Guard Project', tempProjectRoot.path);

      final projectFile = File(p.join(tempProjectRoot.path, 'project.json'));
      await loadProjectUseCase.execute(projectFile.path);

      expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
      expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
    });
  });
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir = Directory(p.join(current.path, 'packages', 'map_editor'));
    if (agentsFile.existsSync() && mapEditorDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not resolve repository root from Directory.current: '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}
```

## 14. Mini conclusion honnete

Le lot 10 reste volontairement simple :
- `project.json` apprend seulement ou se trouvent les donnees Pokemon locales ;
- il n'embarque aucune donnee Pokemon detaillee ;
- il ne lit pas les JSON Pokemon ;
- il ne devance ni l'UI, ni le runtime, ni les imports.

La base est maintenant propre pour la suite :
- le projet sait declarer ses references Pokemon locales ;
- les anciens projets restent compatibles ;
- le manifest reste leger ;
- et la responsabilite des donnees Pokemon detaillees reste bien dans `data/pokemon/...`, pas dans `project.json`.
