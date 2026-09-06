// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectManifest {

 String get name; ProjectVersion get version; List<ProjectMapEntry> get maps; List<ProjectMapGroup> get groups; List<ProjectTilesetFolder> get tilesetFolders; List<ProjectTilesetEntry> get tilesets; List<ProjectElementCategory> get elementCategories; List<ProjectElementEntry> get elements;@JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets) List<EnvironmentPreset> get environmentPresets; List<ProjectEncounterTable> get encounterTables; List<ProjectDialogueFolder> get dialogueFolders; List<ProjectDialogueEntry> get dialogues; List<ProjectScriptEntry> get scripts; List<ScenarioAsset> get scenarios;@JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson) List<CinematicAsset> get cinematics;@JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false) CinematicLibraryCatalog get cinematicLibraryCatalog;@JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false) List<PresentationCinematicAsset> get presentationCinematics;@JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson) List<CinematicMediaAsset> get cinematicMediaAssets;@JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson) List<NarrativeFactDefinition> get facts;@JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson) List<WorldRuleDefinition> get worldRules; List<NarrativeDiagnosticSuppression> get narrativeDiagnosticSuppressions;@JsonKey(includeIfNull: false) NarrativeEventRegistry? get eventRegistry;@JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson) List<SceneAsset> get scenes;@JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson) List<StorylineAsset> get storylines;@JsonKey(includeIfNull: false) RailJourneyCatalog? get railJourneyCatalog; List<ShopDefinition> get shops; List<BadgeDefinition> get badges; List<ProjectTrainerEntry> get trainers; List<ProjectCharacterEntry> get characters;@JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false) ProjectCharacterStudioCatalog get characterStudioCatalog; ProjectSettings get settings;/// Musiques de combat par défaut du projet — BETA-BAT-015.
@JsonKey(includeIfNull: false) ProjectBattleAudioConfig? get battleAudio;/// Transitions de début de combat — BETA-BAT-016.
@JsonKey(includeIfNull: false) ProjectBattleTransitionConfig? get battleTransitions; ProjectPokemonConfig get pokemon; ProjectNewGameConfig get newGame;@JsonKey(includeIfNull: false) ProjectPresentationProfile? get presentation;@JsonKey(includeIfNull: false) ProjectRegionalMapCatalog? get regionalMap; List<ProjectPresentationPresetRecord> get presentationPresets; Map<String, dynamic> get globalProperties;@JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false) ProjectSmartTileCatalog get smartTileCatalog;@JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false) ProjectBorderCatalog get borderCatalog;@ProjectShadowCatalogJsonConverter() ProjectShadowCatalog get shadowCatalog;@JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false) ProjectBuildingShadowPresetCatalog get projectedBuildingShadowCatalog;
/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectManifestCopyWith<ProjectManifest> get copyWith => _$ProjectManifestCopyWithImpl<ProjectManifest>(this as ProjectManifest, _$identity);

  /// Serializes this ProjectManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectManifest&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other.maps, maps)&&const DeepCollectionEquality().equals(other.groups, groups)&&const DeepCollectionEquality().equals(other.tilesetFolders, tilesetFolders)&&const DeepCollectionEquality().equals(other.tilesets, tilesets)&&const DeepCollectionEquality().equals(other.elementCategories, elementCategories)&&const DeepCollectionEquality().equals(other.elements, elements)&&const DeepCollectionEquality().equals(other.environmentPresets, environmentPresets)&&const DeepCollectionEquality().equals(other.encounterTables, encounterTables)&&const DeepCollectionEquality().equals(other.dialogueFolders, dialogueFolders)&&const DeepCollectionEquality().equals(other.dialogues, dialogues)&&const DeepCollectionEquality().equals(other.scripts, scripts)&&const DeepCollectionEquality().equals(other.scenarios, scenarios)&&const DeepCollectionEquality().equals(other.cinematics, cinematics)&&(identical(other.cinematicLibraryCatalog, cinematicLibraryCatalog) || other.cinematicLibraryCatalog == cinematicLibraryCatalog)&&const DeepCollectionEquality().equals(other.presentationCinematics, presentationCinematics)&&const DeepCollectionEquality().equals(other.cinematicMediaAssets, cinematicMediaAssets)&&const DeepCollectionEquality().equals(other.facts, facts)&&const DeepCollectionEquality().equals(other.worldRules, worldRules)&&const DeepCollectionEquality().equals(other.narrativeDiagnosticSuppressions, narrativeDiagnosticSuppressions)&&(identical(other.eventRegistry, eventRegistry) || other.eventRegistry == eventRegistry)&&const DeepCollectionEquality().equals(other.scenes, scenes)&&const DeepCollectionEquality().equals(other.storylines, storylines)&&(identical(other.railJourneyCatalog, railJourneyCatalog) || other.railJourneyCatalog == railJourneyCatalog)&&const DeepCollectionEquality().equals(other.shops, shops)&&const DeepCollectionEquality().equals(other.badges, badges)&&const DeepCollectionEquality().equals(other.trainers, trainers)&&const DeepCollectionEquality().equals(other.characters, characters)&&(identical(other.characterStudioCatalog, characterStudioCatalog) || other.characterStudioCatalog == characterStudioCatalog)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.battleAudio, battleAudio) || other.battleAudio == battleAudio)&&(identical(other.battleTransitions, battleTransitions) || other.battleTransitions == battleTransitions)&&(identical(other.pokemon, pokemon) || other.pokemon == pokemon)&&(identical(other.newGame, newGame) || other.newGame == newGame)&&(identical(other.presentation, presentation) || other.presentation == presentation)&&(identical(other.regionalMap, regionalMap) || other.regionalMap == regionalMap)&&const DeepCollectionEquality().equals(other.presentationPresets, presentationPresets)&&const DeepCollectionEquality().equals(other.globalProperties, globalProperties)&&(identical(other.smartTileCatalog, smartTileCatalog) || other.smartTileCatalog == smartTileCatalog)&&(identical(other.borderCatalog, borderCatalog) || other.borderCatalog == borderCatalog)&&(identical(other.shadowCatalog, shadowCatalog) || other.shadowCatalog == shadowCatalog)&&(identical(other.projectedBuildingShadowCatalog, projectedBuildingShadowCatalog) || other.projectedBuildingShadowCatalog == projectedBuildingShadowCatalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,version,const DeepCollectionEquality().hash(maps),const DeepCollectionEquality().hash(groups),const DeepCollectionEquality().hash(tilesetFolders),const DeepCollectionEquality().hash(tilesets),const DeepCollectionEquality().hash(elementCategories),const DeepCollectionEquality().hash(elements),const DeepCollectionEquality().hash(environmentPresets),const DeepCollectionEquality().hash(encounterTables),const DeepCollectionEquality().hash(dialogueFolders),const DeepCollectionEquality().hash(dialogues),const DeepCollectionEquality().hash(scripts),const DeepCollectionEquality().hash(scenarios),const DeepCollectionEquality().hash(cinematics),cinematicLibraryCatalog,const DeepCollectionEquality().hash(presentationCinematics),const DeepCollectionEquality().hash(cinematicMediaAssets),const DeepCollectionEquality().hash(facts),const DeepCollectionEquality().hash(worldRules),const DeepCollectionEquality().hash(narrativeDiagnosticSuppressions),eventRegistry,const DeepCollectionEquality().hash(scenes),const DeepCollectionEquality().hash(storylines),railJourneyCatalog,const DeepCollectionEquality().hash(shops),const DeepCollectionEquality().hash(badges),const DeepCollectionEquality().hash(trainers),const DeepCollectionEquality().hash(characters),characterStudioCatalog,settings,battleAudio,battleTransitions,pokemon,newGame,presentation,regionalMap,const DeepCollectionEquality().hash(presentationPresets),const DeepCollectionEquality().hash(globalProperties),smartTileCatalog,borderCatalog,shadowCatalog,projectedBuildingShadowCatalog]);

@override
String toString() {
  return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, cinematics: $cinematics, cinematicLibraryCatalog: $cinematicLibraryCatalog, presentationCinematics: $presentationCinematics, cinematicMediaAssets: $cinematicMediaAssets, facts: $facts, worldRules: $worldRules, narrativeDiagnosticSuppressions: $narrativeDiagnosticSuppressions, eventRegistry: $eventRegistry, scenes: $scenes, storylines: $storylines, railJourneyCatalog: $railJourneyCatalog, shops: $shops, badges: $badges, trainers: $trainers, characters: $characters, characterStudioCatalog: $characterStudioCatalog, settings: $settings, battleAudio: $battleAudio, battleTransitions: $battleTransitions, pokemon: $pokemon, newGame: $newGame, presentation: $presentation, regionalMap: $regionalMap, presentationPresets: $presentationPresets, globalProperties: $globalProperties, smartTileCatalog: $smartTileCatalog, borderCatalog: $borderCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
}


}

/// @nodoc
abstract mixin class $ProjectManifestCopyWith<$Res>  {
  factory $ProjectManifestCopyWith(ProjectManifest value, $Res Function(ProjectManifest) _then) = _$ProjectManifestCopyWithImpl;
@useResult
$Res call({
 String name, ProjectVersion version, List<ProjectMapEntry> maps, List<ProjectMapGroup> groups, List<ProjectTilesetFolder> tilesetFolders, List<ProjectTilesetEntry> tilesets, List<ProjectElementCategory> elementCategories, List<ProjectElementEntry> elements,@JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets) List<EnvironmentPreset> environmentPresets, List<ProjectEncounterTable> encounterTables, List<ProjectDialogueFolder> dialogueFolders, List<ProjectDialogueEntry> dialogues, List<ProjectScriptEntry> scripts, List<ScenarioAsset> scenarios,@JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson) List<CinematicAsset> cinematics,@JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false) CinematicLibraryCatalog cinematicLibraryCatalog,@JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false) List<PresentationCinematicAsset> presentationCinematics,@JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson) List<CinematicMediaAsset> cinematicMediaAssets,@JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson) List<NarrativeFactDefinition> facts,@JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson) List<WorldRuleDefinition> worldRules, List<NarrativeDiagnosticSuppression> narrativeDiagnosticSuppressions,@JsonKey(includeIfNull: false) NarrativeEventRegistry? eventRegistry,@JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson) List<SceneAsset> scenes,@JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson) List<StorylineAsset> storylines,@JsonKey(includeIfNull: false) RailJourneyCatalog? railJourneyCatalog, List<ShopDefinition> shops, List<BadgeDefinition> badges, List<ProjectTrainerEntry> trainers, List<ProjectCharacterEntry> characters,@JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false) ProjectCharacterStudioCatalog characterStudioCatalog, ProjectSettings settings,@JsonKey(includeIfNull: false) ProjectBattleAudioConfig? battleAudio,@JsonKey(includeIfNull: false) ProjectBattleTransitionConfig? battleTransitions, ProjectPokemonConfig pokemon, ProjectNewGameConfig newGame,@JsonKey(includeIfNull: false) ProjectPresentationProfile? presentation,@JsonKey(includeIfNull: false) ProjectRegionalMapCatalog? regionalMap, List<ProjectPresentationPresetRecord> presentationPresets, Map<String, dynamic> globalProperties,@JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false) ProjectSmartTileCatalog smartTileCatalog,@JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false) ProjectBorderCatalog borderCatalog,@ProjectShadowCatalogJsonConverter() ProjectShadowCatalog shadowCatalog,@JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false) ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog
});


$RailJourneyCatalogCopyWith<$Res>? get railJourneyCatalog;$ProjectCharacterStudioCatalogCopyWith<$Res> get characterStudioCatalog;$ProjectSettingsCopyWith<$Res> get settings;$ProjectBattleAudioConfigCopyWith<$Res>? get battleAudio;$ProjectBattleTransitionConfigCopyWith<$Res>? get battleTransitions;$ProjectPokemonConfigCopyWith<$Res> get pokemon;$ProjectPresentationProfileCopyWith<$Res>? get presentation;

}
/// @nodoc
class _$ProjectManifestCopyWithImpl<$Res>
    implements $ProjectManifestCopyWith<$Res> {
  _$ProjectManifestCopyWithImpl(this._self, this._then);

  final ProjectManifest _self;
  final $Res Function(ProjectManifest) _then;

/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? version = null,Object? maps = null,Object? groups = null,Object? tilesetFolders = null,Object? tilesets = null,Object? elementCategories = null,Object? elements = null,Object? environmentPresets = null,Object? encounterTables = null,Object? dialogueFolders = null,Object? dialogues = null,Object? scripts = null,Object? scenarios = null,Object? cinematics = null,Object? cinematicLibraryCatalog = null,Object? presentationCinematics = null,Object? cinematicMediaAssets = null,Object? facts = null,Object? worldRules = null,Object? narrativeDiagnosticSuppressions = null,Object? eventRegistry = freezed,Object? scenes = null,Object? storylines = null,Object? railJourneyCatalog = freezed,Object? shops = null,Object? badges = null,Object? trainers = null,Object? characters = null,Object? characterStudioCatalog = null,Object? settings = null,Object? battleAudio = freezed,Object? battleTransitions = freezed,Object? pokemon = null,Object? newGame = null,Object? presentation = freezed,Object? regionalMap = freezed,Object? presentationPresets = null,Object? globalProperties = null,Object? smartTileCatalog = null,Object? borderCatalog = null,Object? shadowCatalog = null,Object? projectedBuildingShadowCatalog = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as ProjectVersion,maps: null == maps ? _self.maps : maps // ignore: cast_nullable_to_non_nullable
as List<ProjectMapEntry>,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<ProjectMapGroup>,tilesetFolders: null == tilesetFolders ? _self.tilesetFolders : tilesetFolders // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetFolder>,tilesets: null == tilesets ? _self.tilesets : tilesets // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetEntry>,elementCategories: null == elementCategories ? _self.elementCategories : elementCategories // ignore: cast_nullable_to_non_nullable
as List<ProjectElementCategory>,elements: null == elements ? _self.elements : elements // ignore: cast_nullable_to_non_nullable
as List<ProjectElementEntry>,environmentPresets: null == environmentPresets ? _self.environmentPresets : environmentPresets // ignore: cast_nullable_to_non_nullable
as List<EnvironmentPreset>,encounterTables: null == encounterTables ? _self.encounterTables : encounterTables // ignore: cast_nullable_to_non_nullable
as List<ProjectEncounterTable>,dialogueFolders: null == dialogueFolders ? _self.dialogueFolders : dialogueFolders // ignore: cast_nullable_to_non_nullable
as List<ProjectDialogueFolder>,dialogues: null == dialogues ? _self.dialogues : dialogues // ignore: cast_nullable_to_non_nullable
as List<ProjectDialogueEntry>,scripts: null == scripts ? _self.scripts : scripts // ignore: cast_nullable_to_non_nullable
as List<ProjectScriptEntry>,scenarios: null == scenarios ? _self.scenarios : scenarios // ignore: cast_nullable_to_non_nullable
as List<ScenarioAsset>,cinematics: null == cinematics ? _self.cinematics : cinematics // ignore: cast_nullable_to_non_nullable
as List<CinematicAsset>,cinematicLibraryCatalog: null == cinematicLibraryCatalog ? _self.cinematicLibraryCatalog : cinematicLibraryCatalog // ignore: cast_nullable_to_non_nullable
as CinematicLibraryCatalog,presentationCinematics: null == presentationCinematics ? _self.presentationCinematics : presentationCinematics // ignore: cast_nullable_to_non_nullable
as List<PresentationCinematicAsset>,cinematicMediaAssets: null == cinematicMediaAssets ? _self.cinematicMediaAssets : cinematicMediaAssets // ignore: cast_nullable_to_non_nullable
as List<CinematicMediaAsset>,facts: null == facts ? _self.facts : facts // ignore: cast_nullable_to_non_nullable
as List<NarrativeFactDefinition>,worldRules: null == worldRules ? _self.worldRules : worldRules // ignore: cast_nullable_to_non_nullable
as List<WorldRuleDefinition>,narrativeDiagnosticSuppressions: null == narrativeDiagnosticSuppressions ? _self.narrativeDiagnosticSuppressions : narrativeDiagnosticSuppressions // ignore: cast_nullable_to_non_nullable
as List<NarrativeDiagnosticSuppression>,eventRegistry: freezed == eventRegistry ? _self.eventRegistry : eventRegistry // ignore: cast_nullable_to_non_nullable
as NarrativeEventRegistry?,scenes: null == scenes ? _self.scenes : scenes // ignore: cast_nullable_to_non_nullable
as List<SceneAsset>,storylines: null == storylines ? _self.storylines : storylines // ignore: cast_nullable_to_non_nullable
as List<StorylineAsset>,railJourneyCatalog: freezed == railJourneyCatalog ? _self.railJourneyCatalog : railJourneyCatalog // ignore: cast_nullable_to_non_nullable
as RailJourneyCatalog?,shops: null == shops ? _self.shops : shops // ignore: cast_nullable_to_non_nullable
as List<ShopDefinition>,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<BadgeDefinition>,trainers: null == trainers ? _self.trainers : trainers // ignore: cast_nullable_to_non_nullable
as List<ProjectTrainerEntry>,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<ProjectCharacterEntry>,characterStudioCatalog: null == characterStudioCatalog ? _self.characterStudioCatalog : characterStudioCatalog // ignore: cast_nullable_to_non_nullable
as ProjectCharacterStudioCatalog,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as ProjectSettings,battleAudio: freezed == battleAudio ? _self.battleAudio : battleAudio // ignore: cast_nullable_to_non_nullable
as ProjectBattleAudioConfig?,battleTransitions: freezed == battleTransitions ? _self.battleTransitions : battleTransitions // ignore: cast_nullable_to_non_nullable
as ProjectBattleTransitionConfig?,pokemon: null == pokemon ? _self.pokemon : pokemon // ignore: cast_nullable_to_non_nullable
as ProjectPokemonConfig,newGame: null == newGame ? _self.newGame : newGame // ignore: cast_nullable_to_non_nullable
as ProjectNewGameConfig,presentation: freezed == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as ProjectPresentationProfile?,regionalMap: freezed == regionalMap ? _self.regionalMap : regionalMap // ignore: cast_nullable_to_non_nullable
as ProjectRegionalMapCatalog?,presentationPresets: null == presentationPresets ? _self.presentationPresets : presentationPresets // ignore: cast_nullable_to_non_nullable
as List<ProjectPresentationPresetRecord>,globalProperties: null == globalProperties ? _self.globalProperties : globalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,smartTileCatalog: null == smartTileCatalog ? _self.smartTileCatalog : smartTileCatalog // ignore: cast_nullable_to_non_nullable
as ProjectSmartTileCatalog,borderCatalog: null == borderCatalog ? _self.borderCatalog : borderCatalog // ignore: cast_nullable_to_non_nullable
as ProjectBorderCatalog,shadowCatalog: null == shadowCatalog ? _self.shadowCatalog : shadowCatalog // ignore: cast_nullable_to_non_nullable
as ProjectShadowCatalog,projectedBuildingShadowCatalog: null == projectedBuildingShadowCatalog ? _self.projectedBuildingShadowCatalog : projectedBuildingShadowCatalog // ignore: cast_nullable_to_non_nullable
as ProjectBuildingShadowPresetCatalog,
  ));
}
/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyCatalogCopyWith<$Res>? get railJourneyCatalog {
    if (_self.railJourneyCatalog == null) {
    return null;
  }

  return $RailJourneyCatalogCopyWith<$Res>(_self.railJourneyCatalog!, (value) {
    return _then(_self.copyWith(railJourneyCatalog: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCharacterStudioCatalogCopyWith<$Res> get characterStudioCatalog {

  return $ProjectCharacterStudioCatalogCopyWith<$Res>(_self.characterStudioCatalog, (value) {
    return _then(_self.copyWith(characterStudioCatalog: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSettingsCopyWith<$Res> get settings {

  return $ProjectSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattleAudioConfigCopyWith<$Res>? get battleAudio {
    if (_self.battleAudio == null) {
    return null;
  }

  return $ProjectBattleAudioConfigCopyWith<$Res>(_self.battleAudio!, (value) {
    return _then(_self.copyWith(battleAudio: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattleTransitionConfigCopyWith<$Res>? get battleTransitions {
    if (_self.battleTransitions == null) {
    return null;
  }

  return $ProjectBattleTransitionConfigCopyWith<$Res>(_self.battleTransitions!, (value) {
    return _then(_self.copyWith(battleTransitions: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPokemonConfigCopyWith<$Res> get pokemon {

  return $ProjectPokemonConfigCopyWith<$Res>(_self.pokemon, (value) {
    return _then(_self.copyWith(pokemon: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPresentationProfileCopyWith<$Res>? get presentation {
    if (_self.presentation == null) {
    return null;
  }

  return $ProjectPresentationProfileCopyWith<$Res>(_self.presentation!, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectManifest].
extension ProjectManifestPatterns on ProjectManifest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectManifest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectManifest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectManifest value)  $default,){
final _that = this;
switch (_that) {
case _ProjectManifest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectManifest value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectManifest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  ProjectVersion version,  List<ProjectMapEntry> maps,  List<ProjectMapGroup> groups,  List<ProjectTilesetFolder> tilesetFolders,  List<ProjectTilesetEntry> tilesets,  List<ProjectElementCategory> elementCategories,  List<ProjectElementEntry> elements, @JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets)  List<EnvironmentPreset> environmentPresets,  List<ProjectEncounterTable> encounterTables,  List<ProjectDialogueFolder> dialogueFolders,  List<ProjectDialogueEntry> dialogues,  List<ProjectScriptEntry> scripts,  List<ScenarioAsset> scenarios, @JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson)  List<CinematicAsset> cinematics, @JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false)  CinematicLibraryCatalog cinematicLibraryCatalog, @JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false)  List<PresentationCinematicAsset> presentationCinematics, @JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson)  List<CinematicMediaAsset> cinematicMediaAssets, @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)  List<NarrativeFactDefinition> facts, @JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson)  List<WorldRuleDefinition> worldRules,  List<NarrativeDiagnosticSuppression> narrativeDiagnosticSuppressions, @JsonKey(includeIfNull: false)  NarrativeEventRegistry? eventRegistry, @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)  List<SceneAsset> scenes, @JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson)  List<StorylineAsset> storylines, @JsonKey(includeIfNull: false)  RailJourneyCatalog? railJourneyCatalog,  List<ShopDefinition> shops,  List<BadgeDefinition> badges,  List<ProjectTrainerEntry> trainers,  List<ProjectCharacterEntry> characters, @JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false)  ProjectCharacterStudioCatalog characterStudioCatalog,  ProjectSettings settings, @JsonKey(includeIfNull: false)  ProjectBattleAudioConfig? battleAudio, @JsonKey(includeIfNull: false)  ProjectBattleTransitionConfig? battleTransitions,  ProjectPokemonConfig pokemon,  ProjectNewGameConfig newGame, @JsonKey(includeIfNull: false)  ProjectPresentationProfile? presentation, @JsonKey(includeIfNull: false)  ProjectRegionalMapCatalog? regionalMap,  List<ProjectPresentationPresetRecord> presentationPresets,  Map<String, dynamic> globalProperties, @JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false)  ProjectSmartTileCatalog smartTileCatalog, @JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false)  ProjectBorderCatalog borderCatalog, @ProjectShadowCatalogJsonConverter()  ProjectShadowCatalog shadowCatalog, @JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false)  ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectManifest() when $default != null:
return $default(_that.name,_that.version,_that.maps,_that.groups,_that.tilesetFolders,_that.tilesets,_that.elementCategories,_that.elements,_that.environmentPresets,_that.encounterTables,_that.dialogueFolders,_that.dialogues,_that.scripts,_that.scenarios,_that.cinematics,_that.cinematicLibraryCatalog,_that.presentationCinematics,_that.cinematicMediaAssets,_that.facts,_that.worldRules,_that.narrativeDiagnosticSuppressions,_that.eventRegistry,_that.scenes,_that.storylines,_that.railJourneyCatalog,_that.shops,_that.badges,_that.trainers,_that.characters,_that.characterStudioCatalog,_that.settings,_that.battleAudio,_that.battleTransitions,_that.pokemon,_that.newGame,_that.presentation,_that.regionalMap,_that.presentationPresets,_that.globalProperties,_that.smartTileCatalog,_that.borderCatalog,_that.shadowCatalog,_that.projectedBuildingShadowCatalog);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  ProjectVersion version,  List<ProjectMapEntry> maps,  List<ProjectMapGroup> groups,  List<ProjectTilesetFolder> tilesetFolders,  List<ProjectTilesetEntry> tilesets,  List<ProjectElementCategory> elementCategories,  List<ProjectElementEntry> elements, @JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets)  List<EnvironmentPreset> environmentPresets,  List<ProjectEncounterTable> encounterTables,  List<ProjectDialogueFolder> dialogueFolders,  List<ProjectDialogueEntry> dialogues,  List<ProjectScriptEntry> scripts,  List<ScenarioAsset> scenarios, @JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson)  List<CinematicAsset> cinematics, @JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false)  CinematicLibraryCatalog cinematicLibraryCatalog, @JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false)  List<PresentationCinematicAsset> presentationCinematics, @JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson)  List<CinematicMediaAsset> cinematicMediaAssets, @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)  List<NarrativeFactDefinition> facts, @JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson)  List<WorldRuleDefinition> worldRules,  List<NarrativeDiagnosticSuppression> narrativeDiagnosticSuppressions, @JsonKey(includeIfNull: false)  NarrativeEventRegistry? eventRegistry, @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)  List<SceneAsset> scenes, @JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson)  List<StorylineAsset> storylines, @JsonKey(includeIfNull: false)  RailJourneyCatalog? railJourneyCatalog,  List<ShopDefinition> shops,  List<BadgeDefinition> badges,  List<ProjectTrainerEntry> trainers,  List<ProjectCharacterEntry> characters, @JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false)  ProjectCharacterStudioCatalog characterStudioCatalog,  ProjectSettings settings, @JsonKey(includeIfNull: false)  ProjectBattleAudioConfig? battleAudio, @JsonKey(includeIfNull: false)  ProjectBattleTransitionConfig? battleTransitions,  ProjectPokemonConfig pokemon,  ProjectNewGameConfig newGame, @JsonKey(includeIfNull: false)  ProjectPresentationProfile? presentation, @JsonKey(includeIfNull: false)  ProjectRegionalMapCatalog? regionalMap,  List<ProjectPresentationPresetRecord> presentationPresets,  Map<String, dynamic> globalProperties, @JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false)  ProjectSmartTileCatalog smartTileCatalog, @JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false)  ProjectBorderCatalog borderCatalog, @ProjectShadowCatalogJsonConverter()  ProjectShadowCatalog shadowCatalog, @JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false)  ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog)  $default,) {final _that = this;
switch (_that) {
case _ProjectManifest():
return $default(_that.name,_that.version,_that.maps,_that.groups,_that.tilesetFolders,_that.tilesets,_that.elementCategories,_that.elements,_that.environmentPresets,_that.encounterTables,_that.dialogueFolders,_that.dialogues,_that.scripts,_that.scenarios,_that.cinematics,_that.cinematicLibraryCatalog,_that.presentationCinematics,_that.cinematicMediaAssets,_that.facts,_that.worldRules,_that.narrativeDiagnosticSuppressions,_that.eventRegistry,_that.scenes,_that.storylines,_that.railJourneyCatalog,_that.shops,_that.badges,_that.trainers,_that.characters,_that.characterStudioCatalog,_that.settings,_that.battleAudio,_that.battleTransitions,_that.pokemon,_that.newGame,_that.presentation,_that.regionalMap,_that.presentationPresets,_that.globalProperties,_that.smartTileCatalog,_that.borderCatalog,_that.shadowCatalog,_that.projectedBuildingShadowCatalog);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  ProjectVersion version,  List<ProjectMapEntry> maps,  List<ProjectMapGroup> groups,  List<ProjectTilesetFolder> tilesetFolders,  List<ProjectTilesetEntry> tilesets,  List<ProjectElementCategory> elementCategories,  List<ProjectElementEntry> elements, @JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets)  List<EnvironmentPreset> environmentPresets,  List<ProjectEncounterTable> encounterTables,  List<ProjectDialogueFolder> dialogueFolders,  List<ProjectDialogueEntry> dialogues,  List<ProjectScriptEntry> scripts,  List<ScenarioAsset> scenarios, @JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson)  List<CinematicAsset> cinematics, @JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false)  CinematicLibraryCatalog cinematicLibraryCatalog, @JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false)  List<PresentationCinematicAsset> presentationCinematics, @JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson)  List<CinematicMediaAsset> cinematicMediaAssets, @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson)  List<NarrativeFactDefinition> facts, @JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson)  List<WorldRuleDefinition> worldRules,  List<NarrativeDiagnosticSuppression> narrativeDiagnosticSuppressions, @JsonKey(includeIfNull: false)  NarrativeEventRegistry? eventRegistry, @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson)  List<SceneAsset> scenes, @JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson)  List<StorylineAsset> storylines, @JsonKey(includeIfNull: false)  RailJourneyCatalog? railJourneyCatalog,  List<ShopDefinition> shops,  List<BadgeDefinition> badges,  List<ProjectTrainerEntry> trainers,  List<ProjectCharacterEntry> characters, @JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false)  ProjectCharacterStudioCatalog characterStudioCatalog,  ProjectSettings settings, @JsonKey(includeIfNull: false)  ProjectBattleAudioConfig? battleAudio, @JsonKey(includeIfNull: false)  ProjectBattleTransitionConfig? battleTransitions,  ProjectPokemonConfig pokemon,  ProjectNewGameConfig newGame, @JsonKey(includeIfNull: false)  ProjectPresentationProfile? presentation, @JsonKey(includeIfNull: false)  ProjectRegionalMapCatalog? regionalMap,  List<ProjectPresentationPresetRecord> presentationPresets,  Map<String, dynamic> globalProperties, @JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false)  ProjectSmartTileCatalog smartTileCatalog, @JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false)  ProjectBorderCatalog borderCatalog, @ProjectShadowCatalogJsonConverter()  ProjectShadowCatalog shadowCatalog, @JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false)  ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog)?  $default,) {final _that = this;
switch (_that) {
case _ProjectManifest() when $default != null:
return $default(_that.name,_that.version,_that.maps,_that.groups,_that.tilesetFolders,_that.tilesets,_that.elementCategories,_that.elements,_that.environmentPresets,_that.encounterTables,_that.dialogueFolders,_that.dialogues,_that.scripts,_that.scenarios,_that.cinematics,_that.cinematicLibraryCatalog,_that.presentationCinematics,_that.cinematicMediaAssets,_that.facts,_that.worldRules,_that.narrativeDiagnosticSuppressions,_that.eventRegistry,_that.scenes,_that.storylines,_that.railJourneyCatalog,_that.shops,_that.badges,_that.trainers,_that.characters,_that.characterStudioCatalog,_that.settings,_that.battleAudio,_that.battleTransitions,_that.pokemon,_that.newGame,_that.presentation,_that.regionalMap,_that.presentationPresets,_that.globalProperties,_that.smartTileCatalog,_that.borderCatalog,_that.shadowCatalog,_that.projectedBuildingShadowCatalog);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectManifest implements ProjectManifest {
  const _ProjectManifest({required this.name, this.version = ProjectVersion.v6, required final  List<ProjectMapEntry> maps, final  List<ProjectMapGroup> groups = const [], final  List<ProjectTilesetFolder> tilesetFolders = const [], required final  List<ProjectTilesetEntry> tilesets, final  List<ProjectElementCategory> elementCategories = const [], final  List<ProjectElementEntry> elements = const [], @JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets) final  List<EnvironmentPreset> environmentPresets = const [], final  List<ProjectEncounterTable> encounterTables = const [], final  List<ProjectDialogueFolder> dialogueFolders = const [], final  List<ProjectDialogueEntry> dialogues = const [], final  List<ProjectScriptEntry> scripts = const [], final  List<ScenarioAsset> scenarios = const [], @JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson) final  List<CinematicAsset> cinematics = const [], @JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false) this.cinematicLibraryCatalog = const CinematicLibraryCatalog.empty(), @JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false) final  List<PresentationCinematicAsset> presentationCinematics = const [], @JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson) final  List<CinematicMediaAsset> cinematicMediaAssets = const [], @JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson) final  List<NarrativeFactDefinition> facts = const [], @JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson) final  List<WorldRuleDefinition> worldRules = const [], final  List<NarrativeDiagnosticSuppression> narrativeDiagnosticSuppressions = const [], @JsonKey(includeIfNull: false) this.eventRegistry, @JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson) final  List<SceneAsset> scenes = const [], @JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson) final  List<StorylineAsset> storylines = const [], @JsonKey(includeIfNull: false) this.railJourneyCatalog, final  List<ShopDefinition> shops = const [], final  List<BadgeDefinition> badges = const [], final  List<ProjectTrainerEntry> trainers = const [], final  List<ProjectCharacterEntry> characters = const [], @JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false) this.characterStudioCatalog = const ProjectCharacterStudioCatalog(), this.settings = const ProjectSettings(), @JsonKey(includeIfNull: false) this.battleAudio, @JsonKey(includeIfNull: false) this.battleTransitions, this.pokemon = const ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1), this.newGame = const ProjectNewGameConfig(), @JsonKey(includeIfNull: false) this.presentation, @JsonKey(includeIfNull: false) this.regionalMap, final  List<ProjectPresentationPresetRecord> presentationPresets = const [], final  Map<String, dynamic> globalProperties = const {}, @JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false) this.smartTileCatalog = const ProjectSmartTileCatalog.empty(), @JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false) this.borderCatalog = const ProjectBorderCatalog.empty(), @ProjectShadowCatalogJsonConverter() this.shadowCatalog = const ProjectShadowCatalog.empty(), @JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false) this.projectedBuildingShadowCatalog = const ProjectBuildingShadowPresetCatalog.empty()}): _maps = maps,_groups = groups,_tilesetFolders = tilesetFolders,_tilesets = tilesets,_elementCategories = elementCategories,_elements = elements,_environmentPresets = environmentPresets,_encounterTables = encounterTables,_dialogueFolders = dialogueFolders,_dialogues = dialogues,_scripts = scripts,_scenarios = scenarios,_cinematics = cinematics,_presentationCinematics = presentationCinematics,_cinematicMediaAssets = cinematicMediaAssets,_facts = facts,_worldRules = worldRules,_narrativeDiagnosticSuppressions = narrativeDiagnosticSuppressions,_scenes = scenes,_storylines = storylines,_shops = shops,_badges = badges,_trainers = trainers,_characters = characters,_presentationPresets = presentationPresets,_globalProperties = globalProperties;
  factory _ProjectManifest.fromJson(Map<String, dynamic> json) => _$ProjectManifestFromJson(json);

@override final  String name;
@override@JsonKey() final  ProjectVersion version;
 final  List<ProjectMapEntry> _maps;
@override List<ProjectMapEntry> get maps {
  if (_maps is EqualUnmodifiableListView) return _maps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_maps);
}

 final  List<ProjectMapGroup> _groups;
@override@JsonKey() List<ProjectMapGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  List<ProjectTilesetFolder> _tilesetFolders;
@override@JsonKey() List<ProjectTilesetFolder> get tilesetFolders {
  if (_tilesetFolders is EqualUnmodifiableListView) return _tilesetFolders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tilesetFolders);
}

 final  List<ProjectTilesetEntry> _tilesets;
@override List<ProjectTilesetEntry> get tilesets {
  if (_tilesets is EqualUnmodifiableListView) return _tilesets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tilesets);
}

 final  List<ProjectElementCategory> _elementCategories;
@override@JsonKey() List<ProjectElementCategory> get elementCategories {
  if (_elementCategories is EqualUnmodifiableListView) return _elementCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elementCategories);
}

 final  List<ProjectElementEntry> _elements;
@override@JsonKey() List<ProjectElementEntry> get elements {
  if (_elements is EqualUnmodifiableListView) return _elements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elements);
}

 final  List<EnvironmentPreset> _environmentPresets;
@override@JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets) List<EnvironmentPreset> get environmentPresets {
  if (_environmentPresets is EqualUnmodifiableListView) return _environmentPresets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_environmentPresets);
}

 final  List<ProjectEncounterTable> _encounterTables;
@override@JsonKey() List<ProjectEncounterTable> get encounterTables {
  if (_encounterTables is EqualUnmodifiableListView) return _encounterTables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_encounterTables);
}

 final  List<ProjectDialogueFolder> _dialogueFolders;
@override@JsonKey() List<ProjectDialogueFolder> get dialogueFolders {
  if (_dialogueFolders is EqualUnmodifiableListView) return _dialogueFolders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dialogueFolders);
}

 final  List<ProjectDialogueEntry> _dialogues;
@override@JsonKey() List<ProjectDialogueEntry> get dialogues {
  if (_dialogues is EqualUnmodifiableListView) return _dialogues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dialogues);
}

 final  List<ProjectScriptEntry> _scripts;
@override@JsonKey() List<ProjectScriptEntry> get scripts {
  if (_scripts is EqualUnmodifiableListView) return _scripts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scripts);
}

 final  List<ScenarioAsset> _scenarios;
@override@JsonKey() List<ScenarioAsset> get scenarios {
  if (_scenarios is EqualUnmodifiableListView) return _scenarios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scenarios);
}

 final  List<CinematicAsset> _cinematics;
@override@JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson) List<CinematicAsset> get cinematics {
  if (_cinematics is EqualUnmodifiableListView) return _cinematics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cinematics);
}

@override@JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false) final  CinematicLibraryCatalog cinematicLibraryCatalog;
 final  List<PresentationCinematicAsset> _presentationCinematics;
@override@JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false) List<PresentationCinematicAsset> get presentationCinematics {
  if (_presentationCinematics is EqualUnmodifiableListView) return _presentationCinematics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presentationCinematics);
}

 final  List<CinematicMediaAsset> _cinematicMediaAssets;
@override@JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson) List<CinematicMediaAsset> get cinematicMediaAssets {
  if (_cinematicMediaAssets is EqualUnmodifiableListView) return _cinematicMediaAssets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cinematicMediaAssets);
}

 final  List<NarrativeFactDefinition> _facts;
@override@JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson) List<NarrativeFactDefinition> get facts {
  if (_facts is EqualUnmodifiableListView) return _facts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_facts);
}

 final  List<WorldRuleDefinition> _worldRules;
@override@JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson) List<WorldRuleDefinition> get worldRules {
  if (_worldRules is EqualUnmodifiableListView) return _worldRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_worldRules);
}

 final  List<NarrativeDiagnosticSuppression> _narrativeDiagnosticSuppressions;
@override@JsonKey() List<NarrativeDiagnosticSuppression> get narrativeDiagnosticSuppressions {
  if (_narrativeDiagnosticSuppressions is EqualUnmodifiableListView) return _narrativeDiagnosticSuppressions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_narrativeDiagnosticSuppressions);
}

@override@JsonKey(includeIfNull: false) final  NarrativeEventRegistry? eventRegistry;
 final  List<SceneAsset> _scenes;
@override@JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson) List<SceneAsset> get scenes {
  if (_scenes is EqualUnmodifiableListView) return _scenes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scenes);
}

 final  List<StorylineAsset> _storylines;
@override@JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson) List<StorylineAsset> get storylines {
  if (_storylines is EqualUnmodifiableListView) return _storylines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_storylines);
}

@override@JsonKey(includeIfNull: false) final  RailJourneyCatalog? railJourneyCatalog;
 final  List<ShopDefinition> _shops;
@override@JsonKey() List<ShopDefinition> get shops {
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shops);
}

 final  List<BadgeDefinition> _badges;
@override@JsonKey() List<BadgeDefinition> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

 final  List<ProjectTrainerEntry> _trainers;
@override@JsonKey() List<ProjectTrainerEntry> get trainers {
  if (_trainers is EqualUnmodifiableListView) return _trainers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trainers);
}

 final  List<ProjectCharacterEntry> _characters;
@override@JsonKey() List<ProjectCharacterEntry> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}

@override@JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false) final  ProjectCharacterStudioCatalog characterStudioCatalog;
@override@JsonKey() final  ProjectSettings settings;
/// Musiques de combat par défaut du projet — BETA-BAT-015.
@override@JsonKey(includeIfNull: false) final  ProjectBattleAudioConfig? battleAudio;
/// Transitions de début de combat — BETA-BAT-016.
@override@JsonKey(includeIfNull: false) final  ProjectBattleTransitionConfig? battleTransitions;
@override@JsonKey() final  ProjectPokemonConfig pokemon;
@override@JsonKey() final  ProjectNewGameConfig newGame;
@override@JsonKey(includeIfNull: false) final  ProjectPresentationProfile? presentation;
@override@JsonKey(includeIfNull: false) final  ProjectRegionalMapCatalog? regionalMap;
 final  List<ProjectPresentationPresetRecord> _presentationPresets;
@override@JsonKey() List<ProjectPresentationPresetRecord> get presentationPresets {
  if (_presentationPresets is EqualUnmodifiableListView) return _presentationPresets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_presentationPresets);
}

 final  Map<String, dynamic> _globalProperties;
@override@JsonKey() Map<String, dynamic> get globalProperties {
  if (_globalProperties is EqualUnmodifiableMapView) return _globalProperties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_globalProperties);
}

@override@JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false) final  ProjectSmartTileCatalog smartTileCatalog;
@override@JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false) final  ProjectBorderCatalog borderCatalog;
@override@JsonKey()@ProjectShadowCatalogJsonConverter() final  ProjectShadowCatalog shadowCatalog;
@override@JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false) final  ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog;

/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectManifestCopyWith<_ProjectManifest> get copyWith => __$ProjectManifestCopyWithImpl<_ProjectManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectManifestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectManifest&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&const DeepCollectionEquality().equals(other._maps, _maps)&&const DeepCollectionEquality().equals(other._groups, _groups)&&const DeepCollectionEquality().equals(other._tilesetFolders, _tilesetFolders)&&const DeepCollectionEquality().equals(other._tilesets, _tilesets)&&const DeepCollectionEquality().equals(other._elementCategories, _elementCategories)&&const DeepCollectionEquality().equals(other._elements, _elements)&&const DeepCollectionEquality().equals(other._environmentPresets, _environmentPresets)&&const DeepCollectionEquality().equals(other._encounterTables, _encounterTables)&&const DeepCollectionEquality().equals(other._dialogueFolders, _dialogueFolders)&&const DeepCollectionEquality().equals(other._dialogues, _dialogues)&&const DeepCollectionEquality().equals(other._scripts, _scripts)&&const DeepCollectionEquality().equals(other._scenarios, _scenarios)&&const DeepCollectionEquality().equals(other._cinematics, _cinematics)&&(identical(other.cinematicLibraryCatalog, cinematicLibraryCatalog) || other.cinematicLibraryCatalog == cinematicLibraryCatalog)&&const DeepCollectionEquality().equals(other._presentationCinematics, _presentationCinematics)&&const DeepCollectionEquality().equals(other._cinematicMediaAssets, _cinematicMediaAssets)&&const DeepCollectionEquality().equals(other._facts, _facts)&&const DeepCollectionEquality().equals(other._worldRules, _worldRules)&&const DeepCollectionEquality().equals(other._narrativeDiagnosticSuppressions, _narrativeDiagnosticSuppressions)&&(identical(other.eventRegistry, eventRegistry) || other.eventRegistry == eventRegistry)&&const DeepCollectionEquality().equals(other._scenes, _scenes)&&const DeepCollectionEquality().equals(other._storylines, _storylines)&&(identical(other.railJourneyCatalog, railJourneyCatalog) || other.railJourneyCatalog == railJourneyCatalog)&&const DeepCollectionEquality().equals(other._shops, _shops)&&const DeepCollectionEquality().equals(other._badges, _badges)&&const DeepCollectionEquality().equals(other._trainers, _trainers)&&const DeepCollectionEquality().equals(other._characters, _characters)&&(identical(other.characterStudioCatalog, characterStudioCatalog) || other.characterStudioCatalog == characterStudioCatalog)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.battleAudio, battleAudio) || other.battleAudio == battleAudio)&&(identical(other.battleTransitions, battleTransitions) || other.battleTransitions == battleTransitions)&&(identical(other.pokemon, pokemon) || other.pokemon == pokemon)&&(identical(other.newGame, newGame) || other.newGame == newGame)&&(identical(other.presentation, presentation) || other.presentation == presentation)&&(identical(other.regionalMap, regionalMap) || other.regionalMap == regionalMap)&&const DeepCollectionEquality().equals(other._presentationPresets, _presentationPresets)&&const DeepCollectionEquality().equals(other._globalProperties, _globalProperties)&&(identical(other.smartTileCatalog, smartTileCatalog) || other.smartTileCatalog == smartTileCatalog)&&(identical(other.borderCatalog, borderCatalog) || other.borderCatalog == borderCatalog)&&(identical(other.shadowCatalog, shadowCatalog) || other.shadowCatalog == shadowCatalog)&&(identical(other.projectedBuildingShadowCatalog, projectedBuildingShadowCatalog) || other.projectedBuildingShadowCatalog == projectedBuildingShadowCatalog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,name,version,const DeepCollectionEquality().hash(_maps),const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(_tilesetFolders),const DeepCollectionEquality().hash(_tilesets),const DeepCollectionEquality().hash(_elementCategories),const DeepCollectionEquality().hash(_elements),const DeepCollectionEquality().hash(_environmentPresets),const DeepCollectionEquality().hash(_encounterTables),const DeepCollectionEquality().hash(_dialogueFolders),const DeepCollectionEquality().hash(_dialogues),const DeepCollectionEquality().hash(_scripts),const DeepCollectionEquality().hash(_scenarios),const DeepCollectionEquality().hash(_cinematics),cinematicLibraryCatalog,const DeepCollectionEquality().hash(_presentationCinematics),const DeepCollectionEquality().hash(_cinematicMediaAssets),const DeepCollectionEquality().hash(_facts),const DeepCollectionEquality().hash(_worldRules),const DeepCollectionEquality().hash(_narrativeDiagnosticSuppressions),eventRegistry,const DeepCollectionEquality().hash(_scenes),const DeepCollectionEquality().hash(_storylines),railJourneyCatalog,const DeepCollectionEquality().hash(_shops),const DeepCollectionEquality().hash(_badges),const DeepCollectionEquality().hash(_trainers),const DeepCollectionEquality().hash(_characters),characterStudioCatalog,settings,battleAudio,battleTransitions,pokemon,newGame,presentation,regionalMap,const DeepCollectionEquality().hash(_presentationPresets),const DeepCollectionEquality().hash(_globalProperties),smartTileCatalog,borderCatalog,shadowCatalog,projectedBuildingShadowCatalog]);

@override
String toString() {
  return 'ProjectManifest(name: $name, version: $version, maps: $maps, groups: $groups, tilesetFolders: $tilesetFolders, tilesets: $tilesets, elementCategories: $elementCategories, elements: $elements, environmentPresets: $environmentPresets, encounterTables: $encounterTables, dialogueFolders: $dialogueFolders, dialogues: $dialogues, scripts: $scripts, scenarios: $scenarios, cinematics: $cinematics, cinematicLibraryCatalog: $cinematicLibraryCatalog, presentationCinematics: $presentationCinematics, cinematicMediaAssets: $cinematicMediaAssets, facts: $facts, worldRules: $worldRules, narrativeDiagnosticSuppressions: $narrativeDiagnosticSuppressions, eventRegistry: $eventRegistry, scenes: $scenes, storylines: $storylines, railJourneyCatalog: $railJourneyCatalog, shops: $shops, badges: $badges, trainers: $trainers, characters: $characters, characterStudioCatalog: $characterStudioCatalog, settings: $settings, battleAudio: $battleAudio, battleTransitions: $battleTransitions, pokemon: $pokemon, newGame: $newGame, presentation: $presentation, regionalMap: $regionalMap, presentationPresets: $presentationPresets, globalProperties: $globalProperties, smartTileCatalog: $smartTileCatalog, borderCatalog: $borderCatalog, shadowCatalog: $shadowCatalog, projectedBuildingShadowCatalog: $projectedBuildingShadowCatalog)';
}


}

/// @nodoc
abstract mixin class _$ProjectManifestCopyWith<$Res> implements $ProjectManifestCopyWith<$Res> {
  factory _$ProjectManifestCopyWith(_ProjectManifest value, $Res Function(_ProjectManifest) _then) = __$ProjectManifestCopyWithImpl;
@override @useResult
$Res call({
 String name, ProjectVersion version, List<ProjectMapEntry> maps, List<ProjectMapGroup> groups, List<ProjectTilesetFolder> tilesetFolders, List<ProjectTilesetEntry> tilesets, List<ProjectElementCategory> elementCategories, List<ProjectElementEntry> elements,@JsonKey(name: 'environmentPresets', fromJson: decodeEnvironmentPresets, toJson: encodeEnvironmentPresets) List<EnvironmentPreset> environmentPresets, List<ProjectEncounterTable> encounterTables, List<ProjectDialogueFolder> dialogueFolders, List<ProjectDialogueEntry> dialogues, List<ProjectScriptEntry> scripts, List<ScenarioAsset> scenarios,@JsonKey(name: 'cinematics', fromJson: _cinematicsFromJson, toJson: _cinematicsToJson) List<CinematicAsset> cinematics,@JsonKey(name: 'cinematicLibraryCatalog', fromJson: _cinematicLibraryCatalogFromJson, toJson: _cinematicLibraryCatalogToJson, includeIfNull: false) CinematicLibraryCatalog cinematicLibraryCatalog,@JsonKey(name: 'presentationCinematics', fromJson: _presentationCinematicsFromJson, toJson: _presentationCinematicsToJson, includeIfNull: false) List<PresentationCinematicAsset> presentationCinematics,@JsonKey(name: 'cinematicMediaAssets', fromJson: _cinematicMediaAssetsFromJson, toJson: _cinematicMediaAssetsToJson) List<CinematicMediaAsset> cinematicMediaAssets,@JsonKey(name: 'facts', fromJson: _factsFromJson, toJson: _factsToJson) List<NarrativeFactDefinition> facts,@JsonKey(name: 'worldRules', fromJson: _worldRulesFromJson, toJson: _worldRulesToJson) List<WorldRuleDefinition> worldRules, List<NarrativeDiagnosticSuppression> narrativeDiagnosticSuppressions,@JsonKey(includeIfNull: false) NarrativeEventRegistry? eventRegistry,@JsonKey(name: 'scenes', fromJson: _scenesFromJson, toJson: _scenesToJson) List<SceneAsset> scenes,@JsonKey(name: 'storylines', fromJson: _storylinesFromJson, toJson: _storylinesToJson) List<StorylineAsset> storylines,@JsonKey(includeIfNull: false) RailJourneyCatalog? railJourneyCatalog, List<ShopDefinition> shops, List<BadgeDefinition> badges, List<ProjectTrainerEntry> trainers, List<ProjectCharacterEntry> characters,@JsonKey(toJson: _projectCharacterStudioCatalogToJson, includeIfNull: false) ProjectCharacterStudioCatalog characterStudioCatalog, ProjectSettings settings,@JsonKey(includeIfNull: false) ProjectBattleAudioConfig? battleAudio,@JsonKey(includeIfNull: false) ProjectBattleTransitionConfig? battleTransitions, ProjectPokemonConfig pokemon, ProjectNewGameConfig newGame,@JsonKey(includeIfNull: false) ProjectPresentationProfile? presentation,@JsonKey(includeIfNull: false) ProjectRegionalMapCatalog? regionalMap, List<ProjectPresentationPresetRecord> presentationPresets, Map<String, dynamic> globalProperties,@JsonKey(name: 'smartTileCatalog', fromJson: _projectSmartTileCatalogFromJson, toJson: _projectSmartTileCatalogToJson, includeIfNull: false) ProjectSmartTileCatalog smartTileCatalog,@JsonKey(name: 'borderCatalog', readValue: _readProjectBorderCatalog, fromJson: _projectBorderCatalogFromJson, toJson: _projectBorderCatalogToJson, includeIfNull: false) ProjectBorderCatalog borderCatalog,@ProjectShadowCatalogJsonConverter() ProjectShadowCatalog shadowCatalog,@JsonKey(name: 'projectedBuildingShadowCatalog', fromJson: _projectedBuildingShadowCatalogFromJson, toJson: _projectedBuildingShadowCatalogToJson, includeIfNull: false) ProjectBuildingShadowPresetCatalog projectedBuildingShadowCatalog
});


@override $RailJourneyCatalogCopyWith<$Res>? get railJourneyCatalog;@override $ProjectCharacterStudioCatalogCopyWith<$Res> get characterStudioCatalog;@override $ProjectSettingsCopyWith<$Res> get settings;@override $ProjectBattleAudioConfigCopyWith<$Res>? get battleAudio;@override $ProjectBattleTransitionConfigCopyWith<$Res>? get battleTransitions;@override $ProjectPokemonConfigCopyWith<$Res> get pokemon;@override $ProjectPresentationProfileCopyWith<$Res>? get presentation;

}
/// @nodoc
class __$ProjectManifestCopyWithImpl<$Res>
    implements _$ProjectManifestCopyWith<$Res> {
  __$ProjectManifestCopyWithImpl(this._self, this._then);

  final _ProjectManifest _self;
  final $Res Function(_ProjectManifest) _then;

/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? version = null,Object? maps = null,Object? groups = null,Object? tilesetFolders = null,Object? tilesets = null,Object? elementCategories = null,Object? elements = null,Object? environmentPresets = null,Object? encounterTables = null,Object? dialogueFolders = null,Object? dialogues = null,Object? scripts = null,Object? scenarios = null,Object? cinematics = null,Object? cinematicLibraryCatalog = null,Object? presentationCinematics = null,Object? cinematicMediaAssets = null,Object? facts = null,Object? worldRules = null,Object? narrativeDiagnosticSuppressions = null,Object? eventRegistry = freezed,Object? scenes = null,Object? storylines = null,Object? railJourneyCatalog = freezed,Object? shops = null,Object? badges = null,Object? trainers = null,Object? characters = null,Object? characterStudioCatalog = null,Object? settings = null,Object? battleAudio = freezed,Object? battleTransitions = freezed,Object? pokemon = null,Object? newGame = null,Object? presentation = freezed,Object? regionalMap = freezed,Object? presentationPresets = null,Object? globalProperties = null,Object? smartTileCatalog = null,Object? borderCatalog = null,Object? shadowCatalog = null,Object? projectedBuildingShadowCatalog = null,}) {
  return _then(_ProjectManifest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as ProjectVersion,maps: null == maps ? _self._maps : maps // ignore: cast_nullable_to_non_nullable
as List<ProjectMapEntry>,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<ProjectMapGroup>,tilesetFolders: null == tilesetFolders ? _self._tilesetFolders : tilesetFolders // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetFolder>,tilesets: null == tilesets ? _self._tilesets : tilesets // ignore: cast_nullable_to_non_nullable
as List<ProjectTilesetEntry>,elementCategories: null == elementCategories ? _self._elementCategories : elementCategories // ignore: cast_nullable_to_non_nullable
as List<ProjectElementCategory>,elements: null == elements ? _self._elements : elements // ignore: cast_nullable_to_non_nullable
as List<ProjectElementEntry>,environmentPresets: null == environmentPresets ? _self._environmentPresets : environmentPresets // ignore: cast_nullable_to_non_nullable
as List<EnvironmentPreset>,encounterTables: null == encounterTables ? _self._encounterTables : encounterTables // ignore: cast_nullable_to_non_nullable
as List<ProjectEncounterTable>,dialogueFolders: null == dialogueFolders ? _self._dialogueFolders : dialogueFolders // ignore: cast_nullable_to_non_nullable
as List<ProjectDialogueFolder>,dialogues: null == dialogues ? _self._dialogues : dialogues // ignore: cast_nullable_to_non_nullable
as List<ProjectDialogueEntry>,scripts: null == scripts ? _self._scripts : scripts // ignore: cast_nullable_to_non_nullable
as List<ProjectScriptEntry>,scenarios: null == scenarios ? _self._scenarios : scenarios // ignore: cast_nullable_to_non_nullable
as List<ScenarioAsset>,cinematics: null == cinematics ? _self._cinematics : cinematics // ignore: cast_nullable_to_non_nullable
as List<CinematicAsset>,cinematicLibraryCatalog: null == cinematicLibraryCatalog ? _self.cinematicLibraryCatalog : cinematicLibraryCatalog // ignore: cast_nullable_to_non_nullable
as CinematicLibraryCatalog,presentationCinematics: null == presentationCinematics ? _self._presentationCinematics : presentationCinematics // ignore: cast_nullable_to_non_nullable
as List<PresentationCinematicAsset>,cinematicMediaAssets: null == cinematicMediaAssets ? _self._cinematicMediaAssets : cinematicMediaAssets // ignore: cast_nullable_to_non_nullable
as List<CinematicMediaAsset>,facts: null == facts ? _self._facts : facts // ignore: cast_nullable_to_non_nullable
as List<NarrativeFactDefinition>,worldRules: null == worldRules ? _self._worldRules : worldRules // ignore: cast_nullable_to_non_nullable
as List<WorldRuleDefinition>,narrativeDiagnosticSuppressions: null == narrativeDiagnosticSuppressions ? _self._narrativeDiagnosticSuppressions : narrativeDiagnosticSuppressions // ignore: cast_nullable_to_non_nullable
as List<NarrativeDiagnosticSuppression>,eventRegistry: freezed == eventRegistry ? _self.eventRegistry : eventRegistry // ignore: cast_nullable_to_non_nullable
as NarrativeEventRegistry?,scenes: null == scenes ? _self._scenes : scenes // ignore: cast_nullable_to_non_nullable
as List<SceneAsset>,storylines: null == storylines ? _self._storylines : storylines // ignore: cast_nullable_to_non_nullable
as List<StorylineAsset>,railJourneyCatalog: freezed == railJourneyCatalog ? _self.railJourneyCatalog : railJourneyCatalog // ignore: cast_nullable_to_non_nullable
as RailJourneyCatalog?,shops: null == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<ShopDefinition>,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<BadgeDefinition>,trainers: null == trainers ? _self._trainers : trainers // ignore: cast_nullable_to_non_nullable
as List<ProjectTrainerEntry>,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<ProjectCharacterEntry>,characterStudioCatalog: null == characterStudioCatalog ? _self.characterStudioCatalog : characterStudioCatalog // ignore: cast_nullable_to_non_nullable
as ProjectCharacterStudioCatalog,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as ProjectSettings,battleAudio: freezed == battleAudio ? _self.battleAudio : battleAudio // ignore: cast_nullable_to_non_nullable
as ProjectBattleAudioConfig?,battleTransitions: freezed == battleTransitions ? _self.battleTransitions : battleTransitions // ignore: cast_nullable_to_non_nullable
as ProjectBattleTransitionConfig?,pokemon: null == pokemon ? _self.pokemon : pokemon // ignore: cast_nullable_to_non_nullable
as ProjectPokemonConfig,newGame: null == newGame ? _self.newGame : newGame // ignore: cast_nullable_to_non_nullable
as ProjectNewGameConfig,presentation: freezed == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as ProjectPresentationProfile?,regionalMap: freezed == regionalMap ? _self.regionalMap : regionalMap // ignore: cast_nullable_to_non_nullable
as ProjectRegionalMapCatalog?,presentationPresets: null == presentationPresets ? _self._presentationPresets : presentationPresets // ignore: cast_nullable_to_non_nullable
as List<ProjectPresentationPresetRecord>,globalProperties: null == globalProperties ? _self._globalProperties : globalProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,smartTileCatalog: null == smartTileCatalog ? _self.smartTileCatalog : smartTileCatalog // ignore: cast_nullable_to_non_nullable
as ProjectSmartTileCatalog,borderCatalog: null == borderCatalog ? _self.borderCatalog : borderCatalog // ignore: cast_nullable_to_non_nullable
as ProjectBorderCatalog,shadowCatalog: null == shadowCatalog ? _self.shadowCatalog : shadowCatalog // ignore: cast_nullable_to_non_nullable
as ProjectShadowCatalog,projectedBuildingShadowCatalog: null == projectedBuildingShadowCatalog ? _self.projectedBuildingShadowCatalog : projectedBuildingShadowCatalog // ignore: cast_nullable_to_non_nullable
as ProjectBuildingShadowPresetCatalog,
  ));
}

/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RailJourneyCatalogCopyWith<$Res>? get railJourneyCatalog {
    if (_self.railJourneyCatalog == null) {
    return null;
  }

  return $RailJourneyCatalogCopyWith<$Res>(_self.railJourneyCatalog!, (value) {
    return _then(_self.copyWith(railJourneyCatalog: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectCharacterStudioCatalogCopyWith<$Res> get characterStudioCatalog {

  return $ProjectCharacterStudioCatalogCopyWith<$Res>(_self.characterStudioCatalog, (value) {
    return _then(_self.copyWith(characterStudioCatalog: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectSettingsCopyWith<$Res> get settings {

  return $ProjectSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattleAudioConfigCopyWith<$Res>? get battleAudio {
    if (_self.battleAudio == null) {
    return null;
  }

  return $ProjectBattleAudioConfigCopyWith<$Res>(_self.battleAudio!, (value) {
    return _then(_self.copyWith(battleAudio: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectBattleTransitionConfigCopyWith<$Res>? get battleTransitions {
    if (_self.battleTransitions == null) {
    return null;
  }

  return $ProjectBattleTransitionConfigCopyWith<$Res>(_self.battleTransitions!, (value) {
    return _then(_self.copyWith(battleTransitions: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPokemonConfigCopyWith<$Res> get pokemon {

  return $ProjectPokemonConfigCopyWith<$Res>(_self.pokemon, (value) {
    return _then(_self.copyWith(pokemon: value));
  });
}/// Create a copy of ProjectManifest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectPresentationProfileCopyWith<$Res>? get presentation {
    if (_self.presentation == null) {
    return null;
  }

  return $ProjectPresentationProfileCopyWith<$Res>(_self.presentation!, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// @nodoc
mixin _$ProjectPokemonConfig {

 bool get enabled; PokemonRulesetProfile get ruleset; String get dataRoot; String get speciesDir; String get learnsetsDir; String get evolutionsDir; String get mediaDir; Map<String, String> get catalogFiles;
/// Create a copy of ProjectPokemonConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectPokemonConfigCopyWith<ProjectPokemonConfig> get copyWith => _$ProjectPokemonConfigCopyWithImpl<ProjectPokemonConfig>(this as ProjectPokemonConfig, _$identity);

  /// Serializes this ProjectPokemonConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectPokemonConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.ruleset, ruleset) || other.ruleset == ruleset)&&(identical(other.dataRoot, dataRoot) || other.dataRoot == dataRoot)&&(identical(other.speciesDir, speciesDir) || other.speciesDir == speciesDir)&&(identical(other.learnsetsDir, learnsetsDir) || other.learnsetsDir == learnsetsDir)&&(identical(other.evolutionsDir, evolutionsDir) || other.evolutionsDir == evolutionsDir)&&(identical(other.mediaDir, mediaDir) || other.mediaDir == mediaDir)&&const DeepCollectionEquality().equals(other.catalogFiles, catalogFiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,ruleset,dataRoot,speciesDir,learnsetsDir,evolutionsDir,mediaDir,const DeepCollectionEquality().hash(catalogFiles));

@override
String toString() {
  return 'ProjectPokemonConfig(enabled: $enabled, ruleset: $ruleset, dataRoot: $dataRoot, speciesDir: $speciesDir, learnsetsDir: $learnsetsDir, evolutionsDir: $evolutionsDir, mediaDir: $mediaDir, catalogFiles: $catalogFiles)';
}


}

/// @nodoc
abstract mixin class $ProjectPokemonConfigCopyWith<$Res>  {
  factory $ProjectPokemonConfigCopyWith(ProjectPokemonConfig value, $Res Function(ProjectPokemonConfig) _then) = _$ProjectPokemonConfigCopyWithImpl;
@useResult
$Res call({
 bool enabled, PokemonRulesetProfile ruleset, String dataRoot, String speciesDir, String learnsetsDir, String evolutionsDir, String mediaDir, Map<String, String> catalogFiles
});




}
/// @nodoc
class _$ProjectPokemonConfigCopyWithImpl<$Res>
    implements $ProjectPokemonConfigCopyWith<$Res> {
  _$ProjectPokemonConfigCopyWithImpl(this._self, this._then);

  final ProjectPokemonConfig _self;
  final $Res Function(ProjectPokemonConfig) _then;

/// Create a copy of ProjectPokemonConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? ruleset = null,Object? dataRoot = null,Object? speciesDir = null,Object? learnsetsDir = null,Object? evolutionsDir = null,Object? mediaDir = null,Object? catalogFiles = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,ruleset: null == ruleset ? _self.ruleset : ruleset // ignore: cast_nullable_to_non_nullable
as PokemonRulesetProfile,dataRoot: null == dataRoot ? _self.dataRoot : dataRoot // ignore: cast_nullable_to_non_nullable
as String,speciesDir: null == speciesDir ? _self.speciesDir : speciesDir // ignore: cast_nullable_to_non_nullable
as String,learnsetsDir: null == learnsetsDir ? _self.learnsetsDir : learnsetsDir // ignore: cast_nullable_to_non_nullable
as String,evolutionsDir: null == evolutionsDir ? _self.evolutionsDir : evolutionsDir // ignore: cast_nullable_to_non_nullable
as String,mediaDir: null == mediaDir ? _self.mediaDir : mediaDir // ignore: cast_nullable_to_non_nullable
as String,catalogFiles: null == catalogFiles ? _self.catalogFiles : catalogFiles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectPokemonConfig].
extension ProjectPokemonConfigPatterns on ProjectPokemonConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectPokemonConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectPokemonConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectPokemonConfig value)  $default,){
final _that = this;
switch (_that) {
case _ProjectPokemonConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectPokemonConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectPokemonConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  PokemonRulesetProfile ruleset,  String dataRoot,  String speciesDir,  String learnsetsDir,  String evolutionsDir,  String mediaDir,  Map<String, String> catalogFiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectPokemonConfig() when $default != null:
return $default(_that.enabled,_that.ruleset,_that.dataRoot,_that.speciesDir,_that.learnsetsDir,_that.evolutionsDir,_that.mediaDir,_that.catalogFiles);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  PokemonRulesetProfile ruleset,  String dataRoot,  String speciesDir,  String learnsetsDir,  String evolutionsDir,  String mediaDir,  Map<String, String> catalogFiles)  $default,) {final _that = this;
switch (_that) {
case _ProjectPokemonConfig():
return $default(_that.enabled,_that.ruleset,_that.dataRoot,_that.speciesDir,_that.learnsetsDir,_that.evolutionsDir,_that.mediaDir,_that.catalogFiles);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  PokemonRulesetProfile ruleset,  String dataRoot,  String speciesDir,  String learnsetsDir,  String evolutionsDir,  String mediaDir,  Map<String, String> catalogFiles)?  $default,) {final _that = this;
switch (_that) {
case _ProjectPokemonConfig() when $default != null:
return $default(_that.enabled,_that.ruleset,_that.dataRoot,_that.speciesDir,_that.learnsetsDir,_that.evolutionsDir,_that.mediaDir,_that.catalogFiles);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectPokemonConfig implements ProjectPokemonConfig {
  const _ProjectPokemonConfig({this.enabled = true, required this.ruleset, this.dataRoot = 'data/pokemon', this.speciesDir = 'data/pokemon/species', this.learnsetsDir = 'data/pokemon/learnsets', this.evolutionsDir = 'data/pokemon/evolutions', this.mediaDir = 'data/pokemon/media', final  Map<String, String> catalogFiles = _defaultPokemonCatalogFiles}): _catalogFiles = catalogFiles;
  factory _ProjectPokemonConfig.fromJson(Map<String, dynamic> json) => _$ProjectPokemonConfigFromJson(json);

@override@JsonKey() final  bool enabled;
@override final  PokemonRulesetProfile ruleset;
@override@JsonKey() final  String dataRoot;
@override@JsonKey() final  String speciesDir;
@override@JsonKey() final  String learnsetsDir;
@override@JsonKey() final  String evolutionsDir;
@override@JsonKey() final  String mediaDir;
 final  Map<String, String> _catalogFiles;
@override@JsonKey() Map<String, String> get catalogFiles {
  if (_catalogFiles is EqualUnmodifiableMapView) return _catalogFiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_catalogFiles);
}


/// Create a copy of ProjectPokemonConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectPokemonConfigCopyWith<_ProjectPokemonConfig> get copyWith => __$ProjectPokemonConfigCopyWithImpl<_ProjectPokemonConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectPokemonConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectPokemonConfig&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.ruleset, ruleset) || other.ruleset == ruleset)&&(identical(other.dataRoot, dataRoot) || other.dataRoot == dataRoot)&&(identical(other.speciesDir, speciesDir) || other.speciesDir == speciesDir)&&(identical(other.learnsetsDir, learnsetsDir) || other.learnsetsDir == learnsetsDir)&&(identical(other.evolutionsDir, evolutionsDir) || other.evolutionsDir == evolutionsDir)&&(identical(other.mediaDir, mediaDir) || other.mediaDir == mediaDir)&&const DeepCollectionEquality().equals(other._catalogFiles, _catalogFiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,ruleset,dataRoot,speciesDir,learnsetsDir,evolutionsDir,mediaDir,const DeepCollectionEquality().hash(_catalogFiles));

@override
String toString() {
  return 'ProjectPokemonConfig(enabled: $enabled, ruleset: $ruleset, dataRoot: $dataRoot, speciesDir: $speciesDir, learnsetsDir: $learnsetsDir, evolutionsDir: $evolutionsDir, mediaDir: $mediaDir, catalogFiles: $catalogFiles)';
}


}

/// @nodoc
abstract mixin class _$ProjectPokemonConfigCopyWith<$Res> implements $ProjectPokemonConfigCopyWith<$Res> {
  factory _$ProjectPokemonConfigCopyWith(_ProjectPokemonConfig value, $Res Function(_ProjectPokemonConfig) _then) = __$ProjectPokemonConfigCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, PokemonRulesetProfile ruleset, String dataRoot, String speciesDir, String learnsetsDir, String evolutionsDir, String mediaDir, Map<String, String> catalogFiles
});




}
/// @nodoc
class __$ProjectPokemonConfigCopyWithImpl<$Res>
    implements _$ProjectPokemonConfigCopyWith<$Res> {
  __$ProjectPokemonConfigCopyWithImpl(this._self, this._then);

  final _ProjectPokemonConfig _self;
  final $Res Function(_ProjectPokemonConfig) _then;

/// Create a copy of ProjectPokemonConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? ruleset = null,Object? dataRoot = null,Object? speciesDir = null,Object? learnsetsDir = null,Object? evolutionsDir = null,Object? mediaDir = null,Object? catalogFiles = null,}) {
  return _then(_ProjectPokemonConfig(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,ruleset: null == ruleset ? _self.ruleset : ruleset // ignore: cast_nullable_to_non_nullable
as PokemonRulesetProfile,dataRoot: null == dataRoot ? _self.dataRoot : dataRoot // ignore: cast_nullable_to_non_nullable
as String,speciesDir: null == speciesDir ? _self.speciesDir : speciesDir // ignore: cast_nullable_to_non_nullable
as String,learnsetsDir: null == learnsetsDir ? _self.learnsetsDir : learnsetsDir // ignore: cast_nullable_to_non_nullable
as String,evolutionsDir: null == evolutionsDir ? _self.evolutionsDir : evolutionsDir // ignore: cast_nullable_to_non_nullable
as String,mediaDir: null == mediaDir ? _self.mediaDir : mediaDir // ignore: cast_nullable_to_non_nullable
as String,catalogFiles: null == catalogFiles ? _self._catalogFiles : catalogFiles // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$ProjectSettings {

 int get tileWidth; int get tileHeight; double get displayScale; int get defaultMapWidth; int get defaultMapHeight;@JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId) String? get defaultPlayerCharacterId;/// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
///
/// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
/// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
@JsonKey(name: 'mistralApiKey', includeIfNull: false) String? get mistralApiKey;
/// Create a copy of ProjectSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectSettingsCopyWith<ProjectSettings> get copyWith => _$ProjectSettingsCopyWithImpl<ProjectSettings>(this as ProjectSettings, _$identity);

  /// Serializes this ProjectSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectSettings&&(identical(other.tileWidth, tileWidth) || other.tileWidth == tileWidth)&&(identical(other.tileHeight, tileHeight) || other.tileHeight == tileHeight)&&(identical(other.displayScale, displayScale) || other.displayScale == displayScale)&&(identical(other.defaultMapWidth, defaultMapWidth) || other.defaultMapWidth == defaultMapWidth)&&(identical(other.defaultMapHeight, defaultMapHeight) || other.defaultMapHeight == defaultMapHeight)&&(identical(other.defaultPlayerCharacterId, defaultPlayerCharacterId) || other.defaultPlayerCharacterId == defaultPlayerCharacterId)&&(identical(other.mistralApiKey, mistralApiKey) || other.mistralApiKey == mistralApiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileWidth,tileHeight,displayScale,defaultMapWidth,defaultMapHeight,defaultPlayerCharacterId,mistralApiKey);

@override
String toString() {
  return 'ProjectSettings(tileWidth: $tileWidth, tileHeight: $tileHeight, displayScale: $displayScale, defaultMapWidth: $defaultMapWidth, defaultMapHeight: $defaultMapHeight, defaultPlayerCharacterId: $defaultPlayerCharacterId, mistralApiKey: $mistralApiKey)';
}


}

/// @nodoc
abstract mixin class $ProjectSettingsCopyWith<$Res>  {
  factory $ProjectSettingsCopyWith(ProjectSettings value, $Res Function(ProjectSettings) _then) = _$ProjectSettingsCopyWithImpl;
@useResult
$Res call({
 int tileWidth, int tileHeight, double displayScale, int defaultMapWidth, int defaultMapHeight,@JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId) String? defaultPlayerCharacterId,@JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey
});




}
/// @nodoc
class _$ProjectSettingsCopyWithImpl<$Res>
    implements $ProjectSettingsCopyWith<$Res> {
  _$ProjectSettingsCopyWithImpl(this._self, this._then);

  final ProjectSettings _self;
  final $Res Function(ProjectSettings) _then;

/// Create a copy of ProjectSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tileWidth = null,Object? tileHeight = null,Object? displayScale = null,Object? defaultMapWidth = null,Object? defaultMapHeight = null,Object? defaultPlayerCharacterId = freezed,Object? mistralApiKey = freezed,}) {
  return _then(_self.copyWith(
tileWidth: null == tileWidth ? _self.tileWidth : tileWidth // ignore: cast_nullable_to_non_nullable
as int,tileHeight: null == tileHeight ? _self.tileHeight : tileHeight // ignore: cast_nullable_to_non_nullable
as int,displayScale: null == displayScale ? _self.displayScale : displayScale // ignore: cast_nullable_to_non_nullable
as double,defaultMapWidth: null == defaultMapWidth ? _self.defaultMapWidth : defaultMapWidth // ignore: cast_nullable_to_non_nullable
as int,defaultMapHeight: null == defaultMapHeight ? _self.defaultMapHeight : defaultMapHeight // ignore: cast_nullable_to_non_nullable
as int,defaultPlayerCharacterId: freezed == defaultPlayerCharacterId ? _self.defaultPlayerCharacterId : defaultPlayerCharacterId // ignore: cast_nullable_to_non_nullable
as String?,mistralApiKey: freezed == mistralApiKey ? _self.mistralApiKey : mistralApiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectSettings].
extension ProjectSettingsPatterns on ProjectSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectSettings value)  $default,){
final _that = this;
switch (_that) {
case _ProjectSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectSettings value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tileWidth,  int tileHeight,  double displayScale,  int defaultMapWidth,  int defaultMapHeight, @JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId)  String? defaultPlayerCharacterId, @JsonKey(name: 'mistralApiKey', includeIfNull: false)  String? mistralApiKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectSettings() when $default != null:
return $default(_that.tileWidth,_that.tileHeight,_that.displayScale,_that.defaultMapWidth,_that.defaultMapHeight,_that.defaultPlayerCharacterId,_that.mistralApiKey);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tileWidth,  int tileHeight,  double displayScale,  int defaultMapWidth,  int defaultMapHeight, @JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId)  String? defaultPlayerCharacterId, @JsonKey(name: 'mistralApiKey', includeIfNull: false)  String? mistralApiKey)  $default,) {final _that = this;
switch (_that) {
case _ProjectSettings():
return $default(_that.tileWidth,_that.tileHeight,_that.displayScale,_that.defaultMapWidth,_that.defaultMapHeight,_that.defaultPlayerCharacterId,_that.mistralApiKey);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tileWidth,  int tileHeight,  double displayScale,  int defaultMapWidth,  int defaultMapHeight, @JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId)  String? defaultPlayerCharacterId, @JsonKey(name: 'mistralApiKey', includeIfNull: false)  String? mistralApiKey)?  $default,) {final _that = this;
switch (_that) {
case _ProjectSettings() when $default != null:
return $default(_that.tileWidth,_that.tileHeight,_that.displayScale,_that.defaultMapWidth,_that.defaultMapHeight,_that.defaultPlayerCharacterId,_that.mistralApiKey);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectSettings implements ProjectSettings {
  const _ProjectSettings({this.tileWidth = 16, this.tileHeight = 16, this.displayScale = 2.0, this.defaultMapWidth = 20, this.defaultMapHeight = 15, @JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId) this.defaultPlayerCharacterId, @JsonKey(name: 'mistralApiKey', includeIfNull: false) this.mistralApiKey});
  factory _ProjectSettings.fromJson(Map<String, dynamic> json) => _$ProjectSettingsFromJson(json);

@override@JsonKey() final  int tileWidth;
@override@JsonKey() final  int tileHeight;
@override@JsonKey() final  double displayScale;
@override@JsonKey() final  int defaultMapWidth;
@override@JsonKey() final  int defaultMapHeight;
@override@JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId) final  String? defaultPlayerCharacterId;
/// Clé API Mistral pour les fonctions IA de l’éditeur (Dialogue Studio, etc.).
///
/// Stockée dans `project.json` : penser au risque de fuite si le dépôt est public ;
/// l’environnement `MISTRAL_API_KEY` reste un repli sans persistance projet.
@override@JsonKey(name: 'mistralApiKey', includeIfNull: false) final  String? mistralApiKey;

/// Create a copy of ProjectSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectSettingsCopyWith<_ProjectSettings> get copyWith => __$ProjectSettingsCopyWithImpl<_ProjectSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectSettings&&(identical(other.tileWidth, tileWidth) || other.tileWidth == tileWidth)&&(identical(other.tileHeight, tileHeight) || other.tileHeight == tileHeight)&&(identical(other.displayScale, displayScale) || other.displayScale == displayScale)&&(identical(other.defaultMapWidth, defaultMapWidth) || other.defaultMapWidth == defaultMapWidth)&&(identical(other.defaultMapHeight, defaultMapHeight) || other.defaultMapHeight == defaultMapHeight)&&(identical(other.defaultPlayerCharacterId, defaultPlayerCharacterId) || other.defaultPlayerCharacterId == defaultPlayerCharacterId)&&(identical(other.mistralApiKey, mistralApiKey) || other.mistralApiKey == mistralApiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tileWidth,tileHeight,displayScale,defaultMapWidth,defaultMapHeight,defaultPlayerCharacterId,mistralApiKey);

@override
String toString() {
  return 'ProjectSettings(tileWidth: $tileWidth, tileHeight: $tileHeight, displayScale: $displayScale, defaultMapWidth: $defaultMapWidth, defaultMapHeight: $defaultMapHeight, defaultPlayerCharacterId: $defaultPlayerCharacterId, mistralApiKey: $mistralApiKey)';
}


}

/// @nodoc
abstract mixin class _$ProjectSettingsCopyWith<$Res> implements $ProjectSettingsCopyWith<$Res> {
  factory _$ProjectSettingsCopyWith(_ProjectSettings value, $Res Function(_ProjectSettings) _then) = __$ProjectSettingsCopyWithImpl;
@override @useResult
$Res call({
 int tileWidth, int tileHeight, double displayScale, int defaultMapWidth, int defaultMapHeight,@JsonKey(name: 'defaultPlayerCharacterId', readValue: _readDefaultPlayerCharacterId) String? defaultPlayerCharacterId,@JsonKey(name: 'mistralApiKey', includeIfNull: false) String? mistralApiKey
});




}
/// @nodoc
class __$ProjectSettingsCopyWithImpl<$Res>
    implements _$ProjectSettingsCopyWith<$Res> {
  __$ProjectSettingsCopyWithImpl(this._self, this._then);

  final _ProjectSettings _self;
  final $Res Function(_ProjectSettings) _then;

/// Create a copy of ProjectSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tileWidth = null,Object? tileHeight = null,Object? displayScale = null,Object? defaultMapWidth = null,Object? defaultMapHeight = null,Object? defaultPlayerCharacterId = freezed,Object? mistralApiKey = freezed,}) {
  return _then(_ProjectSettings(
tileWidth: null == tileWidth ? _self.tileWidth : tileWidth // ignore: cast_nullable_to_non_nullable
as int,tileHeight: null == tileHeight ? _self.tileHeight : tileHeight // ignore: cast_nullable_to_non_nullable
as int,displayScale: null == displayScale ? _self.displayScale : displayScale // ignore: cast_nullable_to_non_nullable
as double,defaultMapWidth: null == defaultMapWidth ? _self.defaultMapWidth : defaultMapWidth // ignore: cast_nullable_to_non_nullable
as int,defaultMapHeight: null == defaultMapHeight ? _self.defaultMapHeight : defaultMapHeight // ignore: cast_nullable_to_non_nullable
as int,defaultPlayerCharacterId: freezed == defaultPlayerCharacterId ? _self.defaultPlayerCharacterId : defaultPlayerCharacterId // ignore: cast_nullable_to_non_nullable
as String?,mistralApiKey: freezed == mistralApiKey ? _self.mistralApiKey : mistralApiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProjectMapGroup {

 String get id; String get name; MapGroupType get type; String? get parentGroupId; int get sortOrder; List<String> get tags; Map<String, dynamic> get properties;
/// Create a copy of ProjectMapGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMapGroupCopyWith<ProjectMapGroup> get copyWith => _$ProjectMapGroupCopyWithImpl<ProjectMapGroup>(this as ProjectMapGroup, _$identity);

  /// Serializes this ProjectMapGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMapGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.parentGroupId, parentGroupId) || other.parentGroupId == parentGroupId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.properties, properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,parentGroupId,sortOrder,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'ProjectMapGroup(id: $id, name: $name, type: $type, parentGroupId: $parentGroupId, sortOrder: $sortOrder, tags: $tags, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $ProjectMapGroupCopyWith<$Res>  {
  factory $ProjectMapGroupCopyWith(ProjectMapGroup value, $Res Function(ProjectMapGroup) _then) = _$ProjectMapGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, MapGroupType type, String? parentGroupId, int sortOrder, List<String> tags, Map<String, dynamic> properties
});




}
/// @nodoc
class _$ProjectMapGroupCopyWithImpl<$Res>
    implements $ProjectMapGroupCopyWith<$Res> {
  _$ProjectMapGroupCopyWithImpl(this._self, this._then);

  final ProjectMapGroup _self;
  final $Res Function(ProjectMapGroup) _then;

/// Create a copy of ProjectMapGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? parentGroupId = freezed,Object? sortOrder = null,Object? tags = null,Object? properties = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MapGroupType,parentGroupId: freezed == parentGroupId ? _self.parentGroupId : parentGroupId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMapGroup].
extension ProjectMapGroupPatterns on ProjectMapGroup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMapGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMapGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMapGroup value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMapGroup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMapGroup value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMapGroup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  MapGroupType type,  String? parentGroupId,  int sortOrder,  List<String> tags,  Map<String, dynamic> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMapGroup() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.parentGroupId,_that.sortOrder,_that.tags,_that.properties);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  MapGroupType type,  String? parentGroupId,  int sortOrder,  List<String> tags,  Map<String, dynamic> properties)  $default,) {final _that = this;
switch (_that) {
case _ProjectMapGroup():
return $default(_that.id,_that.name,_that.type,_that.parentGroupId,_that.sortOrder,_that.tags,_that.properties);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  MapGroupType type,  String? parentGroupId,  int sortOrder,  List<String> tags,  Map<String, dynamic> properties)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMapGroup() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.parentGroupId,_that.sortOrder,_that.tags,_that.properties);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectMapGroup implements ProjectMapGroup {
  const _ProjectMapGroup({required this.id, required this.name, required this.type, this.parentGroupId, this.sortOrder = 0, final  List<String> tags = const [], final  Map<String, dynamic> properties = const {}}): _tags = tags,_properties = properties;
  factory _ProjectMapGroup.fromJson(Map<String, dynamic> json) => _$ProjectMapGroupFromJson(json);

@override final  String id;
@override final  String name;
@override final  MapGroupType type;
@override final  String? parentGroupId;
@override@JsonKey() final  int sortOrder;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  Map<String, dynamic> _properties;
@override@JsonKey() Map<String, dynamic> get properties {
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_properties);
}


/// Create a copy of ProjectMapGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMapGroupCopyWith<_ProjectMapGroup> get copyWith => __$ProjectMapGroupCopyWithImpl<_ProjectMapGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMapGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMapGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.parentGroupId, parentGroupId) || other.parentGroupId == parentGroupId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._properties, _properties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,parentGroupId,sortOrder,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'ProjectMapGroup(id: $id, name: $name, type: $type, parentGroupId: $parentGroupId, sortOrder: $sortOrder, tags: $tags, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$ProjectMapGroupCopyWith<$Res> implements $ProjectMapGroupCopyWith<$Res> {
  factory _$ProjectMapGroupCopyWith(_ProjectMapGroup value, $Res Function(_ProjectMapGroup) _then) = __$ProjectMapGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, MapGroupType type, String? parentGroupId, int sortOrder, List<String> tags, Map<String, dynamic> properties
});




}
/// @nodoc
class __$ProjectMapGroupCopyWithImpl<$Res>
    implements _$ProjectMapGroupCopyWith<$Res> {
  __$ProjectMapGroupCopyWithImpl(this._self, this._then);

  final _ProjectMapGroup _self;
  final $Res Function(_ProjectMapGroup) _then;

/// Create a copy of ProjectMapGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? parentGroupId = freezed,Object? sortOrder = null,Object? tags = null,Object? properties = null,}) {
  return _then(_ProjectMapGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MapGroupType,parentGroupId: freezed == parentGroupId ? _self.parentGroupId : parentGroupId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ProjectMapEntry {

 String get id; String get name; String get relativePath; String? get groupId; MapRole get role; int get sortOrder;
/// Create a copy of ProjectMapEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMapEntryCopyWith<ProjectMapEntry> get copyWith => _$ProjectMapEntryCopyWithImpl<ProjectMapEntry>(this as ProjectMapEntry, _$identity);

  /// Serializes this ProjectMapEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMapEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.role, role) || other.role == role)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,groupId,role,sortOrder);

@override
String toString() {
  return 'ProjectMapEntry(id: $id, name: $name, relativePath: $relativePath, groupId: $groupId, role: $role, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectMapEntryCopyWith<$Res>  {
  factory $ProjectMapEntryCopyWith(ProjectMapEntry value, $Res Function(ProjectMapEntry) _then) = _$ProjectMapEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String relativePath, String? groupId, MapRole role, int sortOrder
});




}
/// @nodoc
class _$ProjectMapEntryCopyWithImpl<$Res>
    implements $ProjectMapEntryCopyWith<$Res> {
  _$ProjectMapEntryCopyWithImpl(this._self, this._then);

  final ProjectMapEntry _self;
  final $Res Function(ProjectMapEntry) _then;

/// Create a copy of ProjectMapEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? groupId = freezed,Object? role = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MapRole,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMapEntry].
extension ProjectMapEntryPatterns on ProjectMapEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMapEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMapEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMapEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMapEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMapEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMapEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath,  String? groupId,  MapRole role,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMapEntry() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.groupId,_that.role,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath,  String? groupId,  MapRole role,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectMapEntry():
return $default(_that.id,_that.name,_that.relativePath,_that.groupId,_that.role,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String relativePath,  String? groupId,  MapRole role,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMapEntry() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.groupId,_that.role,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectMapEntry implements ProjectMapEntry {
  const _ProjectMapEntry({required this.id, required this.name, required this.relativePath, this.groupId, this.role = MapRole.exterior, this.sortOrder = 0});
  factory _ProjectMapEntry.fromJson(Map<String, dynamic> json) => _$ProjectMapEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String relativePath;
@override final  String? groupId;
@override@JsonKey() final  MapRole role;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectMapEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMapEntryCopyWith<_ProjectMapEntry> get copyWith => __$ProjectMapEntryCopyWithImpl<_ProjectMapEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMapEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMapEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.role, role) || other.role == role)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,groupId,role,sortOrder);

@override
String toString() {
  return 'ProjectMapEntry(id: $id, name: $name, relativePath: $relativePath, groupId: $groupId, role: $role, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectMapEntryCopyWith<$Res> implements $ProjectMapEntryCopyWith<$Res> {
  factory _$ProjectMapEntryCopyWith(_ProjectMapEntry value, $Res Function(_ProjectMapEntry) _then) = __$ProjectMapEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String relativePath, String? groupId, MapRole role, int sortOrder
});




}
/// @nodoc
class __$ProjectMapEntryCopyWithImpl<$Res>
    implements _$ProjectMapEntryCopyWith<$Res> {
  __$ProjectMapEntryCopyWithImpl(this._self, this._then);

  final _ProjectMapEntry _self;
  final $Res Function(_ProjectMapEntry) _then;

/// Create a copy of ProjectMapEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? groupId = freezed,Object? role = null,Object? sortOrder = null,}) {
  return _then(_ProjectMapEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MapRole,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectDialogueFolder {

 String get id; String get name; String? get parentFolderId; int get sortOrder;
/// Create a copy of ProjectDialogueFolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDialogueFolderCopyWith<ProjectDialogueFolder> get copyWith => _$ProjectDialogueFolderCopyWithImpl<ProjectDialogueFolder>(this as ProjectDialogueFolder, _$identity);

  /// Serializes this ProjectDialogueFolder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDialogueFolder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentFolderId,sortOrder);

@override
String toString() {
  return 'ProjectDialogueFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectDialogueFolderCopyWith<$Res>  {
  factory $ProjectDialogueFolderCopyWith(ProjectDialogueFolder value, $Res Function(ProjectDialogueFolder) _then) = _$ProjectDialogueFolderCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? parentFolderId, int sortOrder
});




}
/// @nodoc
class _$ProjectDialogueFolderCopyWithImpl<$Res>
    implements $ProjectDialogueFolderCopyWith<$Res> {
  _$ProjectDialogueFolderCopyWithImpl(this._self, this._then);

  final ProjectDialogueFolder _self;
  final $Res Function(ProjectDialogueFolder) _then;

/// Create a copy of ProjectDialogueFolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? parentFolderId = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectDialogueFolder].
extension ProjectDialogueFolderPatterns on ProjectDialogueFolder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectDialogueFolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDialogueFolder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectDialogueFolder value)  $default,){
final _that = this;
switch (_that) {
case _ProjectDialogueFolder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectDialogueFolder value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectDialogueFolder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? parentFolderId,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDialogueFolder() when $default != null:
return $default(_that.id,_that.name,_that.parentFolderId,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? parentFolderId,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectDialogueFolder():
return $default(_that.id,_that.name,_that.parentFolderId,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? parentFolderId,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectDialogueFolder() when $default != null:
return $default(_that.id,_that.name,_that.parentFolderId,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectDialogueFolder implements ProjectDialogueFolder {
  const _ProjectDialogueFolder({required this.id, required this.name, this.parentFolderId, this.sortOrder = 0});
  factory _ProjectDialogueFolder.fromJson(Map<String, dynamic> json) => _$ProjectDialogueFolderFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? parentFolderId;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectDialogueFolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDialogueFolderCopyWith<_ProjectDialogueFolder> get copyWith => __$ProjectDialogueFolderCopyWithImpl<_ProjectDialogueFolder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectDialogueFolderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDialogueFolder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentFolderId,sortOrder);

@override
String toString() {
  return 'ProjectDialogueFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectDialogueFolderCopyWith<$Res> implements $ProjectDialogueFolderCopyWith<$Res> {
  factory _$ProjectDialogueFolderCopyWith(_ProjectDialogueFolder value, $Res Function(_ProjectDialogueFolder) _then) = __$ProjectDialogueFolderCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? parentFolderId, int sortOrder
});




}
/// @nodoc
class __$ProjectDialogueFolderCopyWithImpl<$Res>
    implements _$ProjectDialogueFolderCopyWith<$Res> {
  __$ProjectDialogueFolderCopyWithImpl(this._self, this._then);

  final _ProjectDialogueFolder _self;
  final $Res Function(_ProjectDialogueFolder) _then;

/// Create a copy of ProjectDialogueFolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? parentFolderId = freezed,Object? sortOrder = null,}) {
  return _then(_ProjectDialogueFolder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$DialogueDeclaredOutcome {

 String get id; String get label;
/// Create a copy of DialogueDeclaredOutcome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DialogueDeclaredOutcomeCopyWith<DialogueDeclaredOutcome> get copyWith => _$DialogueDeclaredOutcomeCopyWithImpl<DialogueDeclaredOutcome>(this as DialogueDeclaredOutcome, _$identity);

  /// Serializes this DialogueDeclaredOutcome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DialogueDeclaredOutcome&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'DialogueDeclaredOutcome(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class $DialogueDeclaredOutcomeCopyWith<$Res>  {
  factory $DialogueDeclaredOutcomeCopyWith(DialogueDeclaredOutcome value, $Res Function(DialogueDeclaredOutcome) _then) = _$DialogueDeclaredOutcomeCopyWithImpl;
@useResult
$Res call({
 String id, String label
});




}
/// @nodoc
class _$DialogueDeclaredOutcomeCopyWithImpl<$Res>
    implements $DialogueDeclaredOutcomeCopyWith<$Res> {
  _$DialogueDeclaredOutcomeCopyWithImpl(this._self, this._then);

  final DialogueDeclaredOutcome _self;
  final $Res Function(DialogueDeclaredOutcome) _then;

/// Create a copy of DialogueDeclaredOutcome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DialogueDeclaredOutcome].
extension DialogueDeclaredOutcomePatterns on DialogueDeclaredOutcome {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DialogueDeclaredOutcome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DialogueDeclaredOutcome() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DialogueDeclaredOutcome value)  $default,){
final _that = this;
switch (_that) {
case _DialogueDeclaredOutcome():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DialogueDeclaredOutcome value)?  $default,){
final _that = this;
switch (_that) {
case _DialogueDeclaredOutcome() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DialogueDeclaredOutcome() when $default != null:
return $default(_that.id,_that.label);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label)  $default,) {final _that = this;
switch (_that) {
case _DialogueDeclaredOutcome():
return $default(_that.id,_that.label);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label)?  $default,) {final _that = this;
switch (_that) {
case _DialogueDeclaredOutcome() when $default != null:
return $default(_that.id,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DialogueDeclaredOutcome implements DialogueDeclaredOutcome {
  const _DialogueDeclaredOutcome({required this.id, required this.label});
  factory _DialogueDeclaredOutcome.fromJson(Map<String, dynamic> json) => _$DialogueDeclaredOutcomeFromJson(json);

@override final  String id;
@override final  String label;

/// Create a copy of DialogueDeclaredOutcome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DialogueDeclaredOutcomeCopyWith<_DialogueDeclaredOutcome> get copyWith => __$DialogueDeclaredOutcomeCopyWithImpl<_DialogueDeclaredOutcome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DialogueDeclaredOutcomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DialogueDeclaredOutcome&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'DialogueDeclaredOutcome(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class _$DialogueDeclaredOutcomeCopyWith<$Res> implements $DialogueDeclaredOutcomeCopyWith<$Res> {
  factory _$DialogueDeclaredOutcomeCopyWith(_DialogueDeclaredOutcome value, $Res Function(_DialogueDeclaredOutcome) _then) = __$DialogueDeclaredOutcomeCopyWithImpl;
@override @useResult
$Res call({
 String id, String label
});




}
/// @nodoc
class __$DialogueDeclaredOutcomeCopyWithImpl<$Res>
    implements _$DialogueDeclaredOutcomeCopyWith<$Res> {
  __$DialogueDeclaredOutcomeCopyWithImpl(this._self, this._then);

  final _DialogueDeclaredOutcome _self;
  final $Res Function(_DialogueDeclaredOutcome) _then;

/// Create a copy of DialogueDeclaredOutcome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,}) {
  return _then(_DialogueDeclaredOutcome(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProjectDialogueEntry {

 String get id; String get name;/// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
 String get relativePath; List<String> get tags; String get description; List<DialogueDeclaredOutcome> get declaredOutcomes;/// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
 String? get defaultStartNode;/// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
 String? get folderId; int get sortOrder;
/// Create a copy of ProjectDialogueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDialogueEntryCopyWith<ProjectDialogueEntry> get copyWith => _$ProjectDialogueEntryCopyWithImpl<ProjectDialogueEntry>(this as ProjectDialogueEntry, _$identity);

  /// Serializes this ProjectDialogueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDialogueEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.declaredOutcomes, declaredOutcomes)&&(identical(other.defaultStartNode, defaultStartNode) || other.defaultStartNode == defaultStartNode)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,const DeepCollectionEquality().hash(tags),description,const DeepCollectionEquality().hash(declaredOutcomes),defaultStartNode,folderId,sortOrder);

@override
String toString() {
  return 'ProjectDialogueEntry(id: $id, name: $name, relativePath: $relativePath, tags: $tags, description: $description, declaredOutcomes: $declaredOutcomes, defaultStartNode: $defaultStartNode, folderId: $folderId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectDialogueEntryCopyWith<$Res>  {
  factory $ProjectDialogueEntryCopyWith(ProjectDialogueEntry value, $Res Function(ProjectDialogueEntry) _then) = _$ProjectDialogueEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String relativePath, List<String> tags, String description, List<DialogueDeclaredOutcome> declaredOutcomes, String? defaultStartNode, String? folderId, int sortOrder
});




}
/// @nodoc
class _$ProjectDialogueEntryCopyWithImpl<$Res>
    implements $ProjectDialogueEntryCopyWith<$Res> {
  _$ProjectDialogueEntryCopyWithImpl(this._self, this._then);

  final ProjectDialogueEntry _self;
  final $Res Function(ProjectDialogueEntry) _then;

/// Create a copy of ProjectDialogueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? tags = null,Object? description = null,Object? declaredOutcomes = null,Object? defaultStartNode = freezed,Object? folderId = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,declaredOutcomes: null == declaredOutcomes ? _self.declaredOutcomes : declaredOutcomes // ignore: cast_nullable_to_non_nullable
as List<DialogueDeclaredOutcome>,defaultStartNode: freezed == defaultStartNode ? _self.defaultStartNode : defaultStartNode // ignore: cast_nullable_to_non_nullable
as String?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectDialogueEntry].
extension ProjectDialogueEntryPatterns on ProjectDialogueEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectDialogueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDialogueEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectDialogueEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectDialogueEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectDialogueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectDialogueEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath,  List<String> tags,  String description,  List<DialogueDeclaredOutcome> declaredOutcomes,  String? defaultStartNode,  String? folderId,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDialogueEntry() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.tags,_that.description,_that.declaredOutcomes,_that.defaultStartNode,_that.folderId,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath,  List<String> tags,  String description,  List<DialogueDeclaredOutcome> declaredOutcomes,  String? defaultStartNode,  String? folderId,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectDialogueEntry():
return $default(_that.id,_that.name,_that.relativePath,_that.tags,_that.description,_that.declaredOutcomes,_that.defaultStartNode,_that.folderId,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String relativePath,  List<String> tags,  String description,  List<DialogueDeclaredOutcome> declaredOutcomes,  String? defaultStartNode,  String? folderId,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectDialogueEntry() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.tags,_that.description,_that.declaredOutcomes,_that.defaultStartNode,_that.folderId,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectDialogueEntry implements ProjectDialogueEntry {
  const _ProjectDialogueEntry({required this.id, required this.name, required this.relativePath, final  List<String> tags = const [], this.description = '', final  List<DialogueDeclaredOutcome> declaredOutcomes = const [], this.defaultStartNode, this.folderId, this.sortOrder = 0}): _tags = tags,_declaredOutcomes = declaredOutcomes;
  factory _ProjectDialogueEntry.fromJson(Map<String, dynamic> json) => _$ProjectDialogueEntryFromJson(json);

@override final  String id;
@override final  String name;
/// Chemin relatif à la racine projet, ex. `dialogues/mon_id.yarn`.
@override final  String relativePath;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  String description;
 final  List<DialogueDeclaredOutcome> _declaredOutcomes;
@override@JsonKey() List<DialogueDeclaredOutcome> get declaredOutcomes {
  if (_declaredOutcomes is EqualUnmodifiableListView) return _declaredOutcomes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_declaredOutcomes);
}

/// Nœud Yarn (ou autre) suggéré par défaut dans l'éditeur ; l'entité peut surcharger via [DialogueRef.startNode].
@override final  String? defaultStartNode;
/// Dossier dans [ProjectManifest.dialogueFolders] (bibliothèque scripts) ; null = racine.
@override final  String? folderId;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectDialogueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDialogueEntryCopyWith<_ProjectDialogueEntry> get copyWith => __$ProjectDialogueEntryCopyWithImpl<_ProjectDialogueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectDialogueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDialogueEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._declaredOutcomes, _declaredOutcomes)&&(identical(other.defaultStartNode, defaultStartNode) || other.defaultStartNode == defaultStartNode)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,const DeepCollectionEquality().hash(_tags),description,const DeepCollectionEquality().hash(_declaredOutcomes),defaultStartNode,folderId,sortOrder);

@override
String toString() {
  return 'ProjectDialogueEntry(id: $id, name: $name, relativePath: $relativePath, tags: $tags, description: $description, declaredOutcomes: $declaredOutcomes, defaultStartNode: $defaultStartNode, folderId: $folderId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectDialogueEntryCopyWith<$Res> implements $ProjectDialogueEntryCopyWith<$Res> {
  factory _$ProjectDialogueEntryCopyWith(_ProjectDialogueEntry value, $Res Function(_ProjectDialogueEntry) _then) = __$ProjectDialogueEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String relativePath, List<String> tags, String description, List<DialogueDeclaredOutcome> declaredOutcomes, String? defaultStartNode, String? folderId, int sortOrder
});




}
/// @nodoc
class __$ProjectDialogueEntryCopyWithImpl<$Res>
    implements _$ProjectDialogueEntryCopyWith<$Res> {
  __$ProjectDialogueEntryCopyWithImpl(this._self, this._then);

  final _ProjectDialogueEntry _self;
  final $Res Function(_ProjectDialogueEntry) _then;

/// Create a copy of ProjectDialogueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? tags = null,Object? description = null,Object? declaredOutcomes = null,Object? defaultStartNode = freezed,Object? folderId = freezed,Object? sortOrder = null,}) {
  return _then(_ProjectDialogueEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,declaredOutcomes: null == declaredOutcomes ? _self._declaredOutcomes : declaredOutcomes // ignore: cast_nullable_to_non_nullable
as List<DialogueDeclaredOutcome>,defaultStartNode: freezed == defaultStartNode ? _self.defaultStartNode : defaultStartNode // ignore: cast_nullable_to_non_nullable
as String?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectTilesetFolder {

 String get id; String get name; String? get parentFolderId; int get sortOrder;
/// Create a copy of ProjectTilesetFolder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTilesetFolderCopyWith<ProjectTilesetFolder> get copyWith => _$ProjectTilesetFolderCopyWithImpl<ProjectTilesetFolder>(this as ProjectTilesetFolder, _$identity);

  /// Serializes this ProjectTilesetFolder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTilesetFolder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentFolderId,sortOrder);

@override
String toString() {
  return 'ProjectTilesetFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectTilesetFolderCopyWith<$Res>  {
  factory $ProjectTilesetFolderCopyWith(ProjectTilesetFolder value, $Res Function(ProjectTilesetFolder) _then) = _$ProjectTilesetFolderCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? parentFolderId, int sortOrder
});




}
/// @nodoc
class _$ProjectTilesetFolderCopyWithImpl<$Res>
    implements $ProjectTilesetFolderCopyWith<$Res> {
  _$ProjectTilesetFolderCopyWithImpl(this._self, this._then);

  final ProjectTilesetFolder _self;
  final $Res Function(ProjectTilesetFolder) _then;

/// Create a copy of ProjectTilesetFolder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? parentFolderId = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTilesetFolder].
extension ProjectTilesetFolderPatterns on ProjectTilesetFolder {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTilesetFolder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTilesetFolder() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTilesetFolder value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetFolder():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTilesetFolder value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetFolder() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? parentFolderId,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTilesetFolder() when $default != null:
return $default(_that.id,_that.name,_that.parentFolderId,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? parentFolderId,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetFolder():
return $default(_that.id,_that.name,_that.parentFolderId,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? parentFolderId,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetFolder() when $default != null:
return $default(_that.id,_that.name,_that.parentFolderId,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectTilesetFolder implements ProjectTilesetFolder {
  const _ProjectTilesetFolder({required this.id, required this.name, this.parentFolderId, this.sortOrder = 0});
  factory _ProjectTilesetFolder.fromJson(Map<String, dynamic> json) => _$ProjectTilesetFolderFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? parentFolderId;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectTilesetFolder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTilesetFolderCopyWith<_ProjectTilesetFolder> get copyWith => __$ProjectTilesetFolderCopyWithImpl<_ProjectTilesetFolder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTilesetFolderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTilesetFolder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentFolderId, parentFolderId) || other.parentFolderId == parentFolderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentFolderId,sortOrder);

@override
String toString() {
  return 'ProjectTilesetFolder(id: $id, name: $name, parentFolderId: $parentFolderId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectTilesetFolderCopyWith<$Res> implements $ProjectTilesetFolderCopyWith<$Res> {
  factory _$ProjectTilesetFolderCopyWith(_ProjectTilesetFolder value, $Res Function(_ProjectTilesetFolder) _then) = __$ProjectTilesetFolderCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? parentFolderId, int sortOrder
});




}
/// @nodoc
class __$ProjectTilesetFolderCopyWithImpl<$Res>
    implements _$ProjectTilesetFolderCopyWith<$Res> {
  __$ProjectTilesetFolderCopyWithImpl(this._self, this._then);

  final _ProjectTilesetFolder _self;
  final $Res Function(_ProjectTilesetFolder) _then;

/// Create a copy of ProjectTilesetFolder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? parentFolderId = freezed,Object? sortOrder = null,}) {
  return _then(_ProjectTilesetFolder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentFolderId: freezed == parentFolderId ? _self.parentFolderId : parentFolderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectTilesetEntry {

 String get id; String get name; String get relativePath;@JsonKey(includeIfNull: false) ProjectTilesetSource? get source; TilesetScope get scope; String? get groupId;/// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
 String? get folderId; int get sortOrder; bool get isWorldTileset;@JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false) TilesetTransparentColor? get transparentColor; List<TilesetElementGroup> get elementGroups; List<TilesetPaletteEntry> get paletteEntries;
/// Create a copy of ProjectTilesetEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectTilesetEntryCopyWith<ProjectTilesetEntry> get copyWith => _$ProjectTilesetEntryCopyWithImpl<ProjectTilesetEntry>(this as ProjectTilesetEntry, _$identity);

  /// Serializes this ProjectTilesetEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectTilesetEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.source, source) || other.source == source)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isWorldTileset, isWorldTileset) || other.isWorldTileset == isWorldTileset)&&(identical(other.transparentColor, transparentColor) || other.transparentColor == transparentColor)&&const DeepCollectionEquality().equals(other.elementGroups, elementGroups)&&const DeepCollectionEquality().equals(other.paletteEntries, paletteEntries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,source,scope,groupId,folderId,sortOrder,isWorldTileset,transparentColor,const DeepCollectionEquality().hash(elementGroups),const DeepCollectionEquality().hash(paletteEntries));

@override
String toString() {
  return 'ProjectTilesetEntry(id: $id, name: $name, relativePath: $relativePath, source: $source, scope: $scope, groupId: $groupId, folderId: $folderId, sortOrder: $sortOrder, isWorldTileset: $isWorldTileset, transparentColor: $transparentColor, elementGroups: $elementGroups, paletteEntries: $paletteEntries)';
}


}

/// @nodoc
abstract mixin class $ProjectTilesetEntryCopyWith<$Res>  {
  factory $ProjectTilesetEntryCopyWith(ProjectTilesetEntry value, $Res Function(ProjectTilesetEntry) _then) = _$ProjectTilesetEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String relativePath,@JsonKey(includeIfNull: false) ProjectTilesetSource? source, TilesetScope scope, String? groupId, String? folderId, int sortOrder, bool isWorldTileset,@JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false) TilesetTransparentColor? transparentColor, List<TilesetElementGroup> elementGroups, List<TilesetPaletteEntry> paletteEntries
});




}
/// @nodoc
class _$ProjectTilesetEntryCopyWithImpl<$Res>
    implements $ProjectTilesetEntryCopyWith<$Res> {
  _$ProjectTilesetEntryCopyWithImpl(this._self, this._then);

  final ProjectTilesetEntry _self;
  final $Res Function(ProjectTilesetEntry) _then;

/// Create a copy of ProjectTilesetEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? source = freezed,Object? scope = null,Object? groupId = freezed,Object? folderId = freezed,Object? sortOrder = null,Object? isWorldTileset = null,Object? transparentColor = freezed,Object? elementGroups = null,Object? paletteEntries = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProjectTilesetSource?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as TilesetScope,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isWorldTileset: null == isWorldTileset ? _self.isWorldTileset : isWorldTileset // ignore: cast_nullable_to_non_nullable
as bool,transparentColor: freezed == transparentColor ? _self.transparentColor : transparentColor // ignore: cast_nullable_to_non_nullable
as TilesetTransparentColor?,elementGroups: null == elementGroups ? _self.elementGroups : elementGroups // ignore: cast_nullable_to_non_nullable
as List<TilesetElementGroup>,paletteEntries: null == paletteEntries ? _self.paletteEntries : paletteEntries // ignore: cast_nullable_to_non_nullable
as List<TilesetPaletteEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectTilesetEntry].
extension ProjectTilesetEntryPatterns on ProjectTilesetEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectTilesetEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectTilesetEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectTilesetEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectTilesetEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectTilesetEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath, @JsonKey(includeIfNull: false)  ProjectTilesetSource? source,  TilesetScope scope,  String? groupId,  String? folderId,  int sortOrder,  bool isWorldTileset, @JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false)  TilesetTransparentColor? transparentColor,  List<TilesetElementGroup> elementGroups,  List<TilesetPaletteEntry> paletteEntries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectTilesetEntry() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.source,_that.scope,_that.groupId,_that.folderId,_that.sortOrder,_that.isWorldTileset,_that.transparentColor,_that.elementGroups,_that.paletteEntries);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String relativePath, @JsonKey(includeIfNull: false)  ProjectTilesetSource? source,  TilesetScope scope,  String? groupId,  String? folderId,  int sortOrder,  bool isWorldTileset, @JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false)  TilesetTransparentColor? transparentColor,  List<TilesetElementGroup> elementGroups,  List<TilesetPaletteEntry> paletteEntries)  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetEntry():
return $default(_that.id,_that.name,_that.relativePath,_that.source,_that.scope,_that.groupId,_that.folderId,_that.sortOrder,_that.isWorldTileset,_that.transparentColor,_that.elementGroups,_that.paletteEntries);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String relativePath, @JsonKey(includeIfNull: false)  ProjectTilesetSource? source,  TilesetScope scope,  String? groupId,  String? folderId,  int sortOrder,  bool isWorldTileset, @JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false)  TilesetTransparentColor? transparentColor,  List<TilesetElementGroup> elementGroups,  List<TilesetPaletteEntry> paletteEntries)?  $default,) {final _that = this;
switch (_that) {
case _ProjectTilesetEntry() when $default != null:
return $default(_that.id,_that.name,_that.relativePath,_that.source,_that.scope,_that.groupId,_that.folderId,_that.sortOrder,_that.isWorldTileset,_that.transparentColor,_that.elementGroups,_that.paletteEntries);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectTilesetEntry implements ProjectTilesetEntry {
  const _ProjectTilesetEntry({required this.id, required this.name, required this.relativePath, @JsonKey(includeIfNull: false) this.source, this.scope = TilesetScope.global, this.groupId, this.folderId, this.sortOrder = 0, this.isWorldTileset = false, @JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false) this.transparentColor, final  List<TilesetElementGroup> elementGroups = const [], final  List<TilesetPaletteEntry> paletteEntries = const []}): _elementGroups = elementGroups,_paletteEntries = paletteEntries;
  factory _ProjectTilesetEntry.fromJson(Map<String, dynamic> json) => _$ProjectTilesetEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String relativePath;
@override@JsonKey(includeIfNull: false) final  ProjectTilesetSource? source;
@override@JsonKey() final  TilesetScope scope;
@override final  String? groupId;
/// Dossier de la bibliothèque tilesets (hiérarchie dédiée, distincte des groupes de carte).
@override final  String? folderId;
@override@JsonKey() final  int sortOrder;
@override@JsonKey() final  bool isWorldTileset;
@override@JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false) final  TilesetTransparentColor? transparentColor;
 final  List<TilesetElementGroup> _elementGroups;
@override@JsonKey() List<TilesetElementGroup> get elementGroups {
  if (_elementGroups is EqualUnmodifiableListView) return _elementGroups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elementGroups);
}

 final  List<TilesetPaletteEntry> _paletteEntries;
@override@JsonKey() List<TilesetPaletteEntry> get paletteEntries {
  if (_paletteEntries is EqualUnmodifiableListView) return _paletteEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paletteEntries);
}


/// Create a copy of ProjectTilesetEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectTilesetEntryCopyWith<_ProjectTilesetEntry> get copyWith => __$ProjectTilesetEntryCopyWithImpl<_ProjectTilesetEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectTilesetEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectTilesetEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.relativePath, relativePath) || other.relativePath == relativePath)&&(identical(other.source, source) || other.source == source)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.folderId, folderId) || other.folderId == folderId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isWorldTileset, isWorldTileset) || other.isWorldTileset == isWorldTileset)&&(identical(other.transparentColor, transparentColor) || other.transparentColor == transparentColor)&&const DeepCollectionEquality().equals(other._elementGroups, _elementGroups)&&const DeepCollectionEquality().equals(other._paletteEntries, _paletteEntries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,relativePath,source,scope,groupId,folderId,sortOrder,isWorldTileset,transparentColor,const DeepCollectionEquality().hash(_elementGroups),const DeepCollectionEquality().hash(_paletteEntries));

@override
String toString() {
  return 'ProjectTilesetEntry(id: $id, name: $name, relativePath: $relativePath, source: $source, scope: $scope, groupId: $groupId, folderId: $folderId, sortOrder: $sortOrder, isWorldTileset: $isWorldTileset, transparentColor: $transparentColor, elementGroups: $elementGroups, paletteEntries: $paletteEntries)';
}


}

/// @nodoc
abstract mixin class _$ProjectTilesetEntryCopyWith<$Res> implements $ProjectTilesetEntryCopyWith<$Res> {
  factory _$ProjectTilesetEntryCopyWith(_ProjectTilesetEntry value, $Res Function(_ProjectTilesetEntry) _then) = __$ProjectTilesetEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String relativePath,@JsonKey(includeIfNull: false) ProjectTilesetSource? source, TilesetScope scope, String? groupId, String? folderId, int sortOrder, bool isWorldTileset,@JsonKey(fromJson: _tilesetTransparentColorFromJson, toJson: _tilesetTransparentColorToJson, includeIfNull: false) TilesetTransparentColor? transparentColor, List<TilesetElementGroup> elementGroups, List<TilesetPaletteEntry> paletteEntries
});




}
/// @nodoc
class __$ProjectTilesetEntryCopyWithImpl<$Res>
    implements _$ProjectTilesetEntryCopyWith<$Res> {
  __$ProjectTilesetEntryCopyWithImpl(this._self, this._then);

  final _ProjectTilesetEntry _self;
  final $Res Function(_ProjectTilesetEntry) _then;

/// Create a copy of ProjectTilesetEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? relativePath = null,Object? source = freezed,Object? scope = null,Object? groupId = freezed,Object? folderId = freezed,Object? sortOrder = null,Object? isWorldTileset = null,Object? transparentColor = freezed,Object? elementGroups = null,Object? paletteEntries = null,}) {
  return _then(_ProjectTilesetEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relativePath: null == relativePath ? _self.relativePath : relativePath // ignore: cast_nullable_to_non_nullable
as String,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ProjectTilesetSource?,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as TilesetScope,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,folderId: freezed == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isWorldTileset: null == isWorldTileset ? _self.isWorldTileset : isWorldTileset // ignore: cast_nullable_to_non_nullable
as bool,transparentColor: freezed == transparentColor ? _self.transparentColor : transparentColor // ignore: cast_nullable_to_non_nullable
as TilesetTransparentColor?,elementGroups: null == elementGroups ? _self._elementGroups : elementGroups // ignore: cast_nullable_to_non_nullable
as List<TilesetElementGroup>,paletteEntries: null == paletteEntries ? _self._paletteEntries : paletteEntries // ignore: cast_nullable_to_non_nullable
as List<TilesetPaletteEntry>,
  ));
}


}


/// @nodoc
mixin _$TilesetPaletteEntry {

 String get id; String get name; PaletteCategory get category;/// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
 List<TilesetVisualFrame> get frames; String? get recommendedLayerId;
/// Create a copy of TilesetPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TilesetPaletteEntryCopyWith<TilesetPaletteEntry> get copyWith => _$TilesetPaletteEntryCopyWithImpl<TilesetPaletteEntry>(this as TilesetPaletteEntry, _$identity);

  /// Serializes this TilesetPaletteEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TilesetPaletteEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.recommendedLayerId, recommendedLayerId) || other.recommendedLayerId == recommendedLayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,const DeepCollectionEquality().hash(frames),recommendedLayerId);

@override
String toString() {
  return 'TilesetPaletteEntry(id: $id, name: $name, category: $category, frames: $frames, recommendedLayerId: $recommendedLayerId)';
}


}

/// @nodoc
abstract mixin class $TilesetPaletteEntryCopyWith<$Res>  {
  factory $TilesetPaletteEntryCopyWith(TilesetPaletteEntry value, $Res Function(TilesetPaletteEntry) _then) = _$TilesetPaletteEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, PaletteCategory category, List<TilesetVisualFrame> frames, String? recommendedLayerId
});




}
/// @nodoc
class _$TilesetPaletteEntryCopyWithImpl<$Res>
    implements $TilesetPaletteEntryCopyWith<$Res> {
  _$TilesetPaletteEntryCopyWithImpl(this._self, this._then);

  final TilesetPaletteEntry _self;
  final $Res Function(TilesetPaletteEntry) _then;

/// Create a copy of TilesetPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? frames = null,Object? recommendedLayerId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PaletteCategory,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<TilesetVisualFrame>,recommendedLayerId: freezed == recommendedLayerId ? _self.recommendedLayerId : recommendedLayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TilesetPaletteEntry].
extension TilesetPaletteEntryPatterns on TilesetPaletteEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TilesetPaletteEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TilesetPaletteEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TilesetPaletteEntry value)  $default,){
final _that = this;
switch (_that) {
case _TilesetPaletteEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TilesetPaletteEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TilesetPaletteEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  PaletteCategory category,  List<TilesetVisualFrame> frames,  String? recommendedLayerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TilesetPaletteEntry() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.frames,_that.recommendedLayerId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  PaletteCategory category,  List<TilesetVisualFrame> frames,  String? recommendedLayerId)  $default,) {final _that = this;
switch (_that) {
case _TilesetPaletteEntry():
return $default(_that.id,_that.name,_that.category,_that.frames,_that.recommendedLayerId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  PaletteCategory category,  List<TilesetVisualFrame> frames,  String? recommendedLayerId)?  $default,) {final _that = this;
switch (_that) {
case _TilesetPaletteEntry() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.frames,_that.recommendedLayerId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _TilesetPaletteEntry implements TilesetPaletteEntry {
  const _TilesetPaletteEntry({required this.id, this.name = '', this.category = PaletteCategory.uncategorized, required final  List<TilesetVisualFrame> frames, this.recommendedLayerId}): _frames = frames;
  factory _TilesetPaletteEntry.fromJson(Map<String, dynamic> json) => _$TilesetPaletteEntryFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  PaletteCategory category;
/// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
 final  List<TilesetVisualFrame> _frames;
/// Au moins une frame ; l'éditeur n'affiche pour l'instant que la première.
@override List<TilesetVisualFrame> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override final  String? recommendedLayerId;

/// Create a copy of TilesetPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TilesetPaletteEntryCopyWith<_TilesetPaletteEntry> get copyWith => __$TilesetPaletteEntryCopyWithImpl<_TilesetPaletteEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TilesetPaletteEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TilesetPaletteEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.recommendedLayerId, recommendedLayerId) || other.recommendedLayerId == recommendedLayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,category,const DeepCollectionEquality().hash(_frames),recommendedLayerId);

@override
String toString() {
  return 'TilesetPaletteEntry(id: $id, name: $name, category: $category, frames: $frames, recommendedLayerId: $recommendedLayerId)';
}


}

/// @nodoc
abstract mixin class _$TilesetPaletteEntryCopyWith<$Res> implements $TilesetPaletteEntryCopyWith<$Res> {
  factory _$TilesetPaletteEntryCopyWith(_TilesetPaletteEntry value, $Res Function(_TilesetPaletteEntry) _then) = __$TilesetPaletteEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, PaletteCategory category, List<TilesetVisualFrame> frames, String? recommendedLayerId
});




}
/// @nodoc
class __$TilesetPaletteEntryCopyWithImpl<$Res>
    implements _$TilesetPaletteEntryCopyWith<$Res> {
  __$TilesetPaletteEntryCopyWithImpl(this._self, this._then);

  final _TilesetPaletteEntry _self;
  final $Res Function(_TilesetPaletteEntry) _then;

/// Create a copy of TilesetPaletteEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? frames = null,Object? recommendedLayerId = freezed,}) {
  return _then(_TilesetPaletteEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as PaletteCategory,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<TilesetVisualFrame>,recommendedLayerId: freezed == recommendedLayerId ? _self.recommendedLayerId : recommendedLayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TilesetSourceRect {

 int get x; int get y; int get width; int get height;
/// Create a copy of TilesetSourceRect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TilesetSourceRectCopyWith<TilesetSourceRect> get copyWith => _$TilesetSourceRectCopyWithImpl<TilesetSourceRect>(this as TilesetSourceRect, _$identity);

  /// Serializes this TilesetSourceRect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TilesetSourceRect&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'TilesetSourceRect(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class $TilesetSourceRectCopyWith<$Res>  {
  factory $TilesetSourceRectCopyWith(TilesetSourceRect value, $Res Function(TilesetSourceRect) _then) = _$TilesetSourceRectCopyWithImpl;
@useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class _$TilesetSourceRectCopyWithImpl<$Res>
    implements $TilesetSourceRectCopyWith<$Res> {
  _$TilesetSourceRectCopyWithImpl(this._self, this._then);

  final TilesetSourceRect _self;
  final $Res Function(TilesetSourceRect) _then;

/// Create a copy of TilesetSourceRect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TilesetSourceRect].
extension TilesetSourceRectPatterns on TilesetSourceRect {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TilesetSourceRect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TilesetSourceRect() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TilesetSourceRect value)  $default,){
final _that = this;
switch (_that) {
case _TilesetSourceRect():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TilesetSourceRect value)?  $default,){
final _that = this;
switch (_that) {
case _TilesetSourceRect() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TilesetSourceRect() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int x,  int y,  int width,  int height)  $default,) {final _that = this;
switch (_that) {
case _TilesetSourceRect():
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int x,  int y,  int width,  int height)?  $default,) {final _that = this;
switch (_that) {
case _TilesetSourceRect() when $default != null:
return $default(_that.x,_that.y,_that.width,_that.height);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TilesetSourceRect implements TilesetSourceRect {
  const _TilesetSourceRect({required this.x, required this.y, this.width = 1, this.height = 1});
  factory _TilesetSourceRect.fromJson(Map<String, dynamic> json) => _$TilesetSourceRectFromJson(json);

@override final  int x;
@override final  int y;
@override@JsonKey() final  int width;
@override@JsonKey() final  int height;

/// Create a copy of TilesetSourceRect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TilesetSourceRectCopyWith<_TilesetSourceRect> get copyWith => __$TilesetSourceRectCopyWithImpl<_TilesetSourceRect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TilesetSourceRectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TilesetSourceRect&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,x,y,width,height);

@override
String toString() {
  return 'TilesetSourceRect(x: $x, y: $y, width: $width, height: $height)';
}


}

/// @nodoc
abstract mixin class _$TilesetSourceRectCopyWith<$Res> implements $TilesetSourceRectCopyWith<$Res> {
  factory _$TilesetSourceRectCopyWith(_TilesetSourceRect value, $Res Function(_TilesetSourceRect) _then) = __$TilesetSourceRectCopyWithImpl;
@override @useResult
$Res call({
 int x, int y, int width, int height
});




}
/// @nodoc
class __$TilesetSourceRectCopyWithImpl<$Res>
    implements _$TilesetSourceRectCopyWith<$Res> {
  __$TilesetSourceRectCopyWithImpl(this._self, this._then);

  final _TilesetSourceRect _self;
  final $Res Function(_TilesetSourceRect) _then;

/// Create a copy of TilesetSourceRect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? width = null,Object? height = null,}) {
  return _then(_TilesetSourceRect(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as int,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as int,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as int,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TilesetVisualFrame {

 String get tilesetId; TilesetSourceRect get source;/// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
 int? get durationMs;
/// Create a copy of TilesetVisualFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TilesetVisualFrameCopyWith<TilesetVisualFrame> get copyWith => _$TilesetVisualFrameCopyWithImpl<TilesetVisualFrame>(this as TilesetVisualFrame, _$identity);

  /// Serializes this TilesetVisualFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TilesetVisualFrame&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.source, source) || other.source == source)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tilesetId,source,durationMs);

@override
String toString() {
  return 'TilesetVisualFrame(tilesetId: $tilesetId, source: $source, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $TilesetVisualFrameCopyWith<$Res>  {
  factory $TilesetVisualFrameCopyWith(TilesetVisualFrame value, $Res Function(TilesetVisualFrame) _then) = _$TilesetVisualFrameCopyWithImpl;
@useResult
$Res call({
 String tilesetId, TilesetSourceRect source, int? durationMs
});


$TilesetSourceRectCopyWith<$Res> get source;

}
/// @nodoc
class _$TilesetVisualFrameCopyWithImpl<$Res>
    implements $TilesetVisualFrameCopyWith<$Res> {
  _$TilesetVisualFrameCopyWithImpl(this._self, this._then);

  final TilesetVisualFrame _self;
  final $Res Function(TilesetVisualFrame) _then;

/// Create a copy of TilesetVisualFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tilesetId = null,Object? source = null,Object? durationMs = freezed,}) {
  return _then(_self.copyWith(
tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TilesetSourceRect,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of TilesetVisualFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TilesetSourceRectCopyWith<$Res> get source {

  return $TilesetSourceRectCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [TilesetVisualFrame].
extension TilesetVisualFramePatterns on TilesetVisualFrame {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TilesetVisualFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TilesetVisualFrame() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TilesetVisualFrame value)  $default,){
final _that = this;
switch (_that) {
case _TilesetVisualFrame():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TilesetVisualFrame value)?  $default,){
final _that = this;
switch (_that) {
case _TilesetVisualFrame() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tilesetId,  TilesetSourceRect source,  int? durationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TilesetVisualFrame() when $default != null:
return $default(_that.tilesetId,_that.source,_that.durationMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tilesetId,  TilesetSourceRect source,  int? durationMs)  $default,) {final _that = this;
switch (_that) {
case _TilesetVisualFrame():
return $default(_that.tilesetId,_that.source,_that.durationMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tilesetId,  TilesetSourceRect source,  int? durationMs)?  $default,) {final _that = this;
switch (_that) {
case _TilesetVisualFrame() when $default != null:
return $default(_that.tilesetId,_that.source,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _TilesetVisualFrame implements TilesetVisualFrame {
  const _TilesetVisualFrame({this.tilesetId = '', required this.source, this.durationMs});
  factory _TilesetVisualFrame.fromJson(Map<String, dynamic> json) => _$TilesetVisualFrameFromJson(json);

@override@JsonKey() final  String tilesetId;
@override final  TilesetSourceRect source;
/// Millisecondes d'affichage pour le futur lecteur ; null = statique / défaut moteur.
@override final  int? durationMs;

/// Create a copy of TilesetVisualFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TilesetVisualFrameCopyWith<_TilesetVisualFrame> get copyWith => __$TilesetVisualFrameCopyWithImpl<_TilesetVisualFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TilesetVisualFrameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TilesetVisualFrame&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.source, source) || other.source == source)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tilesetId,source,durationMs);

@override
String toString() {
  return 'TilesetVisualFrame(tilesetId: $tilesetId, source: $source, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$TilesetVisualFrameCopyWith<$Res> implements $TilesetVisualFrameCopyWith<$Res> {
  factory _$TilesetVisualFrameCopyWith(_TilesetVisualFrame value, $Res Function(_TilesetVisualFrame) _then) = __$TilesetVisualFrameCopyWithImpl;
@override @useResult
$Res call({
 String tilesetId, TilesetSourceRect source, int? durationMs
});


@override $TilesetSourceRectCopyWith<$Res> get source;

}
/// @nodoc
class __$TilesetVisualFrameCopyWithImpl<$Res>
    implements _$TilesetVisualFrameCopyWith<$Res> {
  __$TilesetVisualFrameCopyWithImpl(this._self, this._then);

  final _TilesetVisualFrame _self;
  final $Res Function(_TilesetVisualFrame) _then;

/// Create a copy of TilesetVisualFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tilesetId = null,Object? source = null,Object? durationMs = freezed,}) {
  return _then(_TilesetVisualFrame(
tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TilesetSourceRect,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of TilesetVisualFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TilesetSourceRectCopyWith<$Res> get source {

  return $TilesetSourceRectCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// @nodoc
mixin _$TilesetElementGroup {

 String get id; String get name; String? get parentGroupId; int get sortOrder;
/// Create a copy of TilesetElementGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TilesetElementGroupCopyWith<TilesetElementGroup> get copyWith => _$TilesetElementGroupCopyWithImpl<TilesetElementGroup>(this as TilesetElementGroup, _$identity);

  /// Serializes this TilesetElementGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TilesetElementGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentGroupId, parentGroupId) || other.parentGroupId == parentGroupId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentGroupId,sortOrder);

@override
String toString() {
  return 'TilesetElementGroup(id: $id, name: $name, parentGroupId: $parentGroupId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $TilesetElementGroupCopyWith<$Res>  {
  factory $TilesetElementGroupCopyWith(TilesetElementGroup value, $Res Function(TilesetElementGroup) _then) = _$TilesetElementGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? parentGroupId, int sortOrder
});




}
/// @nodoc
class _$TilesetElementGroupCopyWithImpl<$Res>
    implements $TilesetElementGroupCopyWith<$Res> {
  _$TilesetElementGroupCopyWithImpl(this._self, this._then);

  final TilesetElementGroup _self;
  final $Res Function(TilesetElementGroup) _then;

/// Create a copy of TilesetElementGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? parentGroupId = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentGroupId: freezed == parentGroupId ? _self.parentGroupId : parentGroupId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TilesetElementGroup].
extension TilesetElementGroupPatterns on TilesetElementGroup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TilesetElementGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TilesetElementGroup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TilesetElementGroup value)  $default,){
final _that = this;
switch (_that) {
case _TilesetElementGroup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TilesetElementGroup value)?  $default,){
final _that = this;
switch (_that) {
case _TilesetElementGroup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? parentGroupId,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TilesetElementGroup() when $default != null:
return $default(_that.id,_that.name,_that.parentGroupId,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? parentGroupId,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _TilesetElementGroup():
return $default(_that.id,_that.name,_that.parentGroupId,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? parentGroupId,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _TilesetElementGroup() when $default != null:
return $default(_that.id,_that.name,_that.parentGroupId,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TilesetElementGroup implements TilesetElementGroup {
  const _TilesetElementGroup({required this.id, required this.name, this.parentGroupId, this.sortOrder = 0});
  factory _TilesetElementGroup.fromJson(Map<String, dynamic> json) => _$TilesetElementGroupFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? parentGroupId;
@override@JsonKey() final  int sortOrder;

/// Create a copy of TilesetElementGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TilesetElementGroupCopyWith<_TilesetElementGroup> get copyWith => __$TilesetElementGroupCopyWithImpl<_TilesetElementGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TilesetElementGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TilesetElementGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentGroupId, parentGroupId) || other.parentGroupId == parentGroupId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentGroupId,sortOrder);

@override
String toString() {
  return 'TilesetElementGroup(id: $id, name: $name, parentGroupId: $parentGroupId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$TilesetElementGroupCopyWith<$Res> implements $TilesetElementGroupCopyWith<$Res> {
  factory _$TilesetElementGroupCopyWith(_TilesetElementGroup value, $Res Function(_TilesetElementGroup) _then) = __$TilesetElementGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? parentGroupId, int sortOrder
});




}
/// @nodoc
class __$TilesetElementGroupCopyWithImpl<$Res>
    implements _$TilesetElementGroupCopyWith<$Res> {
  __$TilesetElementGroupCopyWithImpl(this._self, this._then);

  final _TilesetElementGroup _self;
  final $Res Function(_TilesetElementGroup) _then;

/// Create a copy of TilesetElementGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? parentGroupId = freezed,Object? sortOrder = null,}) {
  return _then(_TilesetElementGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentGroupId: freezed == parentGroupId ? _self.parentGroupId : parentGroupId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectElementCategory {

 String get id; String get name; String? get parentCategoryId; int get sortOrder;
/// Create a copy of ProjectElementCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectElementCategoryCopyWith<ProjectElementCategory> get copyWith => _$ProjectElementCategoryCopyWithImpl<ProjectElementCategory>(this as ProjectElementCategory, _$identity);

  /// Serializes this ProjectElementCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectElementCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentCategoryId,sortOrder);

@override
String toString() {
  return 'ProjectElementCategory(id: $id, name: $name, parentCategoryId: $parentCategoryId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectElementCategoryCopyWith<$Res>  {
  factory $ProjectElementCategoryCopyWith(ProjectElementCategory value, $Res Function(ProjectElementCategory) _then) = _$ProjectElementCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? parentCategoryId, int sortOrder
});




}
/// @nodoc
class _$ProjectElementCategoryCopyWithImpl<$Res>
    implements $ProjectElementCategoryCopyWith<$Res> {
  _$ProjectElementCategoryCopyWithImpl(this._self, this._then);

  final ProjectElementCategory _self;
  final $Res Function(ProjectElementCategory) _then;

/// Create a copy of ProjectElementCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? parentCategoryId = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectElementCategory].
extension ProjectElementCategoryPatterns on ProjectElementCategory {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectElementCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectElementCategory() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectElementCategory value)  $default,){
final _that = this;
switch (_that) {
case _ProjectElementCategory():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectElementCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectElementCategory() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? parentCategoryId,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectElementCategory() when $default != null:
return $default(_that.id,_that.name,_that.parentCategoryId,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? parentCategoryId,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectElementCategory():
return $default(_that.id,_that.name,_that.parentCategoryId,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? parentCategoryId,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectElementCategory() when $default != null:
return $default(_that.id,_that.name,_that.parentCategoryId,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectElementCategory implements ProjectElementCategory {
  const _ProjectElementCategory({required this.id, required this.name, this.parentCategoryId, this.sortOrder = 0});
  factory _ProjectElementCategory.fromJson(Map<String, dynamic> json) => _$ProjectElementCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? parentCategoryId;
@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectElementCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectElementCategoryCopyWith<_ProjectElementCategory> get copyWith => __$ProjectElementCategoryCopyWithImpl<_ProjectElementCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectElementCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectElementCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentCategoryId, parentCategoryId) || other.parentCategoryId == parentCategoryId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentCategoryId,sortOrder);

@override
String toString() {
  return 'ProjectElementCategory(id: $id, name: $name, parentCategoryId: $parentCategoryId, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectElementCategoryCopyWith<$Res> implements $ProjectElementCategoryCopyWith<$Res> {
  factory _$ProjectElementCategoryCopyWith(_ProjectElementCategory value, $Res Function(_ProjectElementCategory) _then) = __$ProjectElementCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? parentCategoryId, int sortOrder
});




}
/// @nodoc
class __$ProjectElementCategoryCopyWithImpl<$Res>
    implements _$ProjectElementCategoryCopyWith<$Res> {
  __$ProjectElementCategoryCopyWithImpl(this._self, this._then);

  final _ProjectElementCategory _self;
  final $Res Function(_ProjectElementCategory) _then;

/// Create a copy of ProjectElementCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? parentCategoryId = freezed,Object? sortOrder = null,}) {
  return _then(_ProjectElementCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentCategoryId: freezed == parentCategoryId ? _self.parentCategoryId : parentCategoryId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProjectElementEntry {

 String get id; String get name; String get tilesetId; String get categoryId; String? get tilesetGroupId;/// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
 List<TilesetVisualFrame> get frames; ElementPresetKind get presetKind; ElementCollisionProfile? get collisionProfile;@ProjectElementShadowConfigJsonConverter() ProjectElementShadowConfig? get shadow;@JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false) ProjectElementProjectedBuildingShadowConfig? get projectedBuildingShadow; String? get groupId; String? get recommendedLayerId; List<String> get tags; int get sortOrder;
/// Create a copy of ProjectElementEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectElementEntryCopyWith<ProjectElementEntry> get copyWith => _$ProjectElementEntryCopyWithImpl<ProjectElementEntry>(this as ProjectElementEntry, _$identity);

  /// Serializes this ProjectElementEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectElementEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.tilesetGroupId, tilesetGroupId) || other.tilesetGroupId == tilesetGroupId)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.presetKind, presetKind) || other.presetKind == presetKind)&&(identical(other.collisionProfile, collisionProfile) || other.collisionProfile == collisionProfile)&&(identical(other.shadow, shadow) || other.shadow == shadow)&&(identical(other.projectedBuildingShadow, projectedBuildingShadow) || other.projectedBuildingShadow == projectedBuildingShadow)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.recommendedLayerId, recommendedLayerId) || other.recommendedLayerId == recommendedLayerId)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tilesetId,categoryId,tilesetGroupId,const DeepCollectionEquality().hash(frames),presetKind,collisionProfile,shadow,projectedBuildingShadow,groupId,recommendedLayerId,const DeepCollectionEquality().hash(tags),sortOrder);

@override
String toString() {
  return 'ProjectElementEntry(id: $id, name: $name, tilesetId: $tilesetId, categoryId: $categoryId, tilesetGroupId: $tilesetGroupId, frames: $frames, presetKind: $presetKind, collisionProfile: $collisionProfile, shadow: $shadow, projectedBuildingShadow: $projectedBuildingShadow, groupId: $groupId, recommendedLayerId: $recommendedLayerId, tags: $tags, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectElementEntryCopyWith<$Res>  {
  factory $ProjectElementEntryCopyWith(ProjectElementEntry value, $Res Function(ProjectElementEntry) _then) = _$ProjectElementEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tilesetId, String categoryId, String? tilesetGroupId, List<TilesetVisualFrame> frames, ElementPresetKind presetKind, ElementCollisionProfile? collisionProfile,@ProjectElementShadowConfigJsonConverter() ProjectElementShadowConfig? shadow,@JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false) ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow, String? groupId, String? recommendedLayerId, List<String> tags, int sortOrder
});


$ElementCollisionProfileCopyWith<$Res>? get collisionProfile;

}
/// @nodoc
class _$ProjectElementEntryCopyWithImpl<$Res>
    implements $ProjectElementEntryCopyWith<$Res> {
  _$ProjectElementEntryCopyWithImpl(this._self, this._then);

  final ProjectElementEntry _self;
  final $Res Function(ProjectElementEntry) _then;

/// Create a copy of ProjectElementEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tilesetId = null,Object? categoryId = null,Object? tilesetGroupId = freezed,Object? frames = null,Object? presetKind = null,Object? collisionProfile = freezed,Object? shadow = freezed,Object? projectedBuildingShadow = freezed,Object? groupId = freezed,Object? recommendedLayerId = freezed,Object? tags = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,tilesetGroupId: freezed == tilesetGroupId ? _self.tilesetGroupId : tilesetGroupId // ignore: cast_nullable_to_non_nullable
as String?,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<TilesetVisualFrame>,presetKind: null == presetKind ? _self.presetKind : presetKind // ignore: cast_nullable_to_non_nullable
as ElementPresetKind,collisionProfile: freezed == collisionProfile ? _self.collisionProfile : collisionProfile // ignore: cast_nullable_to_non_nullable
as ElementCollisionProfile?,shadow: freezed == shadow ? _self.shadow : shadow // ignore: cast_nullable_to_non_nullable
as ProjectElementShadowConfig?,projectedBuildingShadow: freezed == projectedBuildingShadow ? _self.projectedBuildingShadow : projectedBuildingShadow // ignore: cast_nullable_to_non_nullable
as ProjectElementProjectedBuildingShadowConfig?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,recommendedLayerId: freezed == recommendedLayerId ? _self.recommendedLayerId : recommendedLayerId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ProjectElementEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionProfileCopyWith<$Res>? get collisionProfile {
    if (_self.collisionProfile == null) {
    return null;
  }

  return $ElementCollisionProfileCopyWith<$Res>(_self.collisionProfile!, (value) {
    return _then(_self.copyWith(collisionProfile: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectElementEntry].
extension ProjectElementEntryPatterns on ProjectElementEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectElementEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectElementEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectElementEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectElementEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectElementEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectElementEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tilesetId,  String categoryId,  String? tilesetGroupId,  List<TilesetVisualFrame> frames,  ElementPresetKind presetKind,  ElementCollisionProfile? collisionProfile, @ProjectElementShadowConfigJsonConverter()  ProjectElementShadowConfig? shadow, @JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false)  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,  String? groupId,  String? recommendedLayerId,  List<String> tags,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectElementEntry() when $default != null:
return $default(_that.id,_that.name,_that.tilesetId,_that.categoryId,_that.tilesetGroupId,_that.frames,_that.presetKind,_that.collisionProfile,_that.shadow,_that.projectedBuildingShadow,_that.groupId,_that.recommendedLayerId,_that.tags,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tilesetId,  String categoryId,  String? tilesetGroupId,  List<TilesetVisualFrame> frames,  ElementPresetKind presetKind,  ElementCollisionProfile? collisionProfile, @ProjectElementShadowConfigJsonConverter()  ProjectElementShadowConfig? shadow, @JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false)  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,  String? groupId,  String? recommendedLayerId,  List<String> tags,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectElementEntry():
return $default(_that.id,_that.name,_that.tilesetId,_that.categoryId,_that.tilesetGroupId,_that.frames,_that.presetKind,_that.collisionProfile,_that.shadow,_that.projectedBuildingShadow,_that.groupId,_that.recommendedLayerId,_that.tags,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tilesetId,  String categoryId,  String? tilesetGroupId,  List<TilesetVisualFrame> frames,  ElementPresetKind presetKind,  ElementCollisionProfile? collisionProfile, @ProjectElementShadowConfigJsonConverter()  ProjectElementShadowConfig? shadow, @JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false)  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,  String? groupId,  String? recommendedLayerId,  List<String> tags,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectElementEntry() when $default != null:
return $default(_that.id,_that.name,_that.tilesetId,_that.categoryId,_that.tilesetGroupId,_that.frames,_that.presetKind,_that.collisionProfile,_that.shadow,_that.projectedBuildingShadow,_that.groupId,_that.recommendedLayerId,_that.tags,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectElementEntry implements ProjectElementEntry {
  const _ProjectElementEntry({required this.id, required this.name, required this.tilesetId, required this.categoryId, this.tilesetGroupId, required final  List<TilesetVisualFrame> frames, this.presetKind = ElementPresetKind.generic, this.collisionProfile, @ProjectElementShadowConfigJsonConverter() this.shadow, @JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false) this.projectedBuildingShadow, this.groupId, this.recommendedLayerId, final  List<String> tags = const [], this.sortOrder = 0}): _frames = frames,_tags = tags;
  factory _ProjectElementEntry.fromJson(Map<String, dynamic> json) => _$ProjectElementEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String tilesetId;
@override final  String categoryId;
@override final  String? tilesetGroupId;
/// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
 final  List<TilesetVisualFrame> _frames;
/// Au moins une frame ; le canvas map_editor anime les entités qui référencent cet élément via toutes les frames (durées `durationMs` ou fallback) ; autres usages éditeur (pinceau, etc.) = première frame.
@override List<TilesetVisualFrame> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override@JsonKey() final  ElementPresetKind presetKind;
@override final  ElementCollisionProfile? collisionProfile;
@override@ProjectElementShadowConfigJsonConverter() final  ProjectElementShadowConfig? shadow;
@override@JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false) final  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow;
@override final  String? groupId;
@override final  String? recommendedLayerId;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectElementEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectElementEntryCopyWith<_ProjectElementEntry> get copyWith => __$ProjectElementEntryCopyWithImpl<_ProjectElementEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectElementEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectElementEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.tilesetGroupId, tilesetGroupId) || other.tilesetGroupId == tilesetGroupId)&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.presetKind, presetKind) || other.presetKind == presetKind)&&(identical(other.collisionProfile, collisionProfile) || other.collisionProfile == collisionProfile)&&(identical(other.shadow, shadow) || other.shadow == shadow)&&(identical(other.projectedBuildingShadow, projectedBuildingShadow) || other.projectedBuildingShadow == projectedBuildingShadow)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.recommendedLayerId, recommendedLayerId) || other.recommendedLayerId == recommendedLayerId)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tilesetId,categoryId,tilesetGroupId,const DeepCollectionEquality().hash(_frames),presetKind,collisionProfile,shadow,projectedBuildingShadow,groupId,recommendedLayerId,const DeepCollectionEquality().hash(_tags),sortOrder);

@override
String toString() {
  return 'ProjectElementEntry(id: $id, name: $name, tilesetId: $tilesetId, categoryId: $categoryId, tilesetGroupId: $tilesetGroupId, frames: $frames, presetKind: $presetKind, collisionProfile: $collisionProfile, shadow: $shadow, projectedBuildingShadow: $projectedBuildingShadow, groupId: $groupId, recommendedLayerId: $recommendedLayerId, tags: $tags, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectElementEntryCopyWith<$Res> implements $ProjectElementEntryCopyWith<$Res> {
  factory _$ProjectElementEntryCopyWith(_ProjectElementEntry value, $Res Function(_ProjectElementEntry) _then) = __$ProjectElementEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tilesetId, String categoryId, String? tilesetGroupId, List<TilesetVisualFrame> frames, ElementPresetKind presetKind, ElementCollisionProfile? collisionProfile,@ProjectElementShadowConfigJsonConverter() ProjectElementShadowConfig? shadow,@JsonKey(name: 'projectedBuildingShadow', fromJson: _projectedBuildingShadowConfigFromJson, toJson: _projectedBuildingShadowConfigToJson, includeIfNull: false) ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow, String? groupId, String? recommendedLayerId, List<String> tags, int sortOrder
});


@override $ElementCollisionProfileCopyWith<$Res>? get collisionProfile;

}
/// @nodoc
class __$ProjectElementEntryCopyWithImpl<$Res>
    implements _$ProjectElementEntryCopyWith<$Res> {
  __$ProjectElementEntryCopyWithImpl(this._self, this._then);

  final _ProjectElementEntry _self;
  final $Res Function(_ProjectElementEntry) _then;

/// Create a copy of ProjectElementEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tilesetId = null,Object? categoryId = null,Object? tilesetGroupId = freezed,Object? frames = null,Object? presetKind = null,Object? collisionProfile = freezed,Object? shadow = freezed,Object? projectedBuildingShadow = freezed,Object? groupId = freezed,Object? recommendedLayerId = freezed,Object? tags = null,Object? sortOrder = null,}) {
  return _then(_ProjectElementEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,tilesetGroupId: freezed == tilesetGroupId ? _self.tilesetGroupId : tilesetGroupId // ignore: cast_nullable_to_non_nullable
as String?,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<TilesetVisualFrame>,presetKind: null == presetKind ? _self.presetKind : presetKind // ignore: cast_nullable_to_non_nullable
as ElementPresetKind,collisionProfile: freezed == collisionProfile ? _self.collisionProfile : collisionProfile // ignore: cast_nullable_to_non_nullable
as ElementCollisionProfile?,shadow: freezed == shadow ? _self.shadow : shadow // ignore: cast_nullable_to_non_nullable
as ProjectElementShadowConfig?,projectedBuildingShadow: freezed == projectedBuildingShadow ? _self.projectedBuildingShadow : projectedBuildingShadow // ignore: cast_nullable_to_non_nullable
as ProjectElementProjectedBuildingShadowConfig?,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,recommendedLayerId: freezed == recommendedLayerId ? _self.recommendedLayerId : recommendedLayerId // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ProjectElementEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ElementCollisionProfileCopyWith<$Res>? get collisionProfile {
    if (_self.collisionProfile == null) {
    return null;
  }

  return $ElementCollisionProfileCopyWith<$Res>(_self.collisionProfile!, (value) {
    return _then(_self.copyWith(collisionProfile: value));
  });
}
}


/// @nodoc
mixin _$ProjectEncounterPokemonOverrides {

 String? get natureId; String? get abilityId; String? get gender; PokemonStatSpread? get ivs; ProjectEncounterShinyPolicy get shinyPolicy; List<String> get knownMoveIds;
/// Create a copy of ProjectEncounterPokemonOverrides
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectEncounterPokemonOverridesCopyWith<ProjectEncounterPokemonOverrides> get copyWith => _$ProjectEncounterPokemonOverridesCopyWithImpl<ProjectEncounterPokemonOverrides>(this as ProjectEncounterPokemonOverrides, _$identity);

  /// Serializes this ProjectEncounterPokemonOverrides to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectEncounterPokemonOverrides&&(identical(other.natureId, natureId) || other.natureId == natureId)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.ivs, ivs) || other.ivs == ivs)&&(identical(other.shinyPolicy, shinyPolicy) || other.shinyPolicy == shinyPolicy)&&const DeepCollectionEquality().equals(other.knownMoveIds, knownMoveIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,natureId,abilityId,gender,ivs,shinyPolicy,const DeepCollectionEquality().hash(knownMoveIds));

@override
String toString() {
  return 'ProjectEncounterPokemonOverrides(natureId: $natureId, abilityId: $abilityId, gender: $gender, ivs: $ivs, shinyPolicy: $shinyPolicy, knownMoveIds: $knownMoveIds)';
}


}

/// @nodoc
abstract mixin class $ProjectEncounterPokemonOverridesCopyWith<$Res>  {
  factory $ProjectEncounterPokemonOverridesCopyWith(ProjectEncounterPokemonOverrides value, $Res Function(ProjectEncounterPokemonOverrides) _then) = _$ProjectEncounterPokemonOverridesCopyWithImpl;
@useResult
$Res call({
 String? natureId, String? abilityId, String? gender, PokemonStatSpread? ivs, ProjectEncounterShinyPolicy shinyPolicy, List<String> knownMoveIds
});


$PokemonStatSpreadCopyWith<$Res>? get ivs;

}
/// @nodoc
class _$ProjectEncounterPokemonOverridesCopyWithImpl<$Res>
    implements $ProjectEncounterPokemonOverridesCopyWith<$Res> {
  _$ProjectEncounterPokemonOverridesCopyWithImpl(this._self, this._then);

  final ProjectEncounterPokemonOverrides _self;
  final $Res Function(ProjectEncounterPokemonOverrides) _then;

/// Create a copy of ProjectEncounterPokemonOverrides
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? natureId = freezed,Object? abilityId = freezed,Object? gender = freezed,Object? ivs = freezed,Object? shinyPolicy = null,Object? knownMoveIds = null,}) {
  return _then(_self.copyWith(
natureId: freezed == natureId ? _self.natureId : natureId // ignore: cast_nullable_to_non_nullable
as String?,abilityId: freezed == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,ivs: freezed == ivs ? _self.ivs : ivs // ignore: cast_nullable_to_non_nullable
as PokemonStatSpread?,shinyPolicy: null == shinyPolicy ? _self.shinyPolicy : shinyPolicy // ignore: cast_nullable_to_non_nullable
as ProjectEncounterShinyPolicy,knownMoveIds: null == knownMoveIds ? _self.knownMoveIds : knownMoveIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ProjectEncounterPokemonOverrides
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<$Res>? get ivs {
    if (_self.ivs == null) {
    return null;
  }

  return $PokemonStatSpreadCopyWith<$Res>(_self.ivs!, (value) {
    return _then(_self.copyWith(ivs: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectEncounterPokemonOverrides].
extension ProjectEncounterPokemonOverridesPatterns on ProjectEncounterPokemonOverrides {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectEncounterPokemonOverrides value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectEncounterPokemonOverrides() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectEncounterPokemonOverrides value)  $default,){
final _that = this;
switch (_that) {
case _ProjectEncounterPokemonOverrides():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectEncounterPokemonOverrides value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectEncounterPokemonOverrides() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? natureId,  String? abilityId,  String? gender,  PokemonStatSpread? ivs,  ProjectEncounterShinyPolicy shinyPolicy,  List<String> knownMoveIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectEncounterPokemonOverrides() when $default != null:
return $default(_that.natureId,_that.abilityId,_that.gender,_that.ivs,_that.shinyPolicy,_that.knownMoveIds);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? natureId,  String? abilityId,  String? gender,  PokemonStatSpread? ivs,  ProjectEncounterShinyPolicy shinyPolicy,  List<String> knownMoveIds)  $default,) {final _that = this;
switch (_that) {
case _ProjectEncounterPokemonOverrides():
return $default(_that.natureId,_that.abilityId,_that.gender,_that.ivs,_that.shinyPolicy,_that.knownMoveIds);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? natureId,  String? abilityId,  String? gender,  PokemonStatSpread? ivs,  ProjectEncounterShinyPolicy shinyPolicy,  List<String> knownMoveIds)?  $default,) {final _that = this;
switch (_that) {
case _ProjectEncounterPokemonOverrides() when $default != null:
return $default(_that.natureId,_that.abilityId,_that.gender,_that.ivs,_that.shinyPolicy,_that.knownMoveIds);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectEncounterPokemonOverrides implements ProjectEncounterPokemonOverrides {
  const _ProjectEncounterPokemonOverrides({this.natureId, this.abilityId, this.gender, this.ivs, this.shinyPolicy = ProjectEncounterShinyPolicy.random, final  List<String> knownMoveIds = const <String>[]}): _knownMoveIds = knownMoveIds;
  factory _ProjectEncounterPokemonOverrides.fromJson(Map<String, dynamic> json) => _$ProjectEncounterPokemonOverridesFromJson(json);

@override final  String? natureId;
@override final  String? abilityId;
@override final  String? gender;
@override final  PokemonStatSpread? ivs;
@override@JsonKey() final  ProjectEncounterShinyPolicy shinyPolicy;
 final  List<String> _knownMoveIds;
@override@JsonKey() List<String> get knownMoveIds {
  if (_knownMoveIds is EqualUnmodifiableListView) return _knownMoveIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_knownMoveIds);
}


/// Create a copy of ProjectEncounterPokemonOverrides
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectEncounterPokemonOverridesCopyWith<_ProjectEncounterPokemonOverrides> get copyWith => __$ProjectEncounterPokemonOverridesCopyWithImpl<_ProjectEncounterPokemonOverrides>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectEncounterPokemonOverridesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectEncounterPokemonOverrides&&(identical(other.natureId, natureId) || other.natureId == natureId)&&(identical(other.abilityId, abilityId) || other.abilityId == abilityId)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.ivs, ivs) || other.ivs == ivs)&&(identical(other.shinyPolicy, shinyPolicy) || other.shinyPolicy == shinyPolicy)&&const DeepCollectionEquality().equals(other._knownMoveIds, _knownMoveIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,natureId,abilityId,gender,ivs,shinyPolicy,const DeepCollectionEquality().hash(_knownMoveIds));

@override
String toString() {
  return 'ProjectEncounterPokemonOverrides(natureId: $natureId, abilityId: $abilityId, gender: $gender, ivs: $ivs, shinyPolicy: $shinyPolicy, knownMoveIds: $knownMoveIds)';
}


}

/// @nodoc
abstract mixin class _$ProjectEncounterPokemonOverridesCopyWith<$Res> implements $ProjectEncounterPokemonOverridesCopyWith<$Res> {
  factory _$ProjectEncounterPokemonOverridesCopyWith(_ProjectEncounterPokemonOverrides value, $Res Function(_ProjectEncounterPokemonOverrides) _then) = __$ProjectEncounterPokemonOverridesCopyWithImpl;
@override @useResult
$Res call({
 String? natureId, String? abilityId, String? gender, PokemonStatSpread? ivs, ProjectEncounterShinyPolicy shinyPolicy, List<String> knownMoveIds
});


@override $PokemonStatSpreadCopyWith<$Res>? get ivs;

}
/// @nodoc
class __$ProjectEncounterPokemonOverridesCopyWithImpl<$Res>
    implements _$ProjectEncounterPokemonOverridesCopyWith<$Res> {
  __$ProjectEncounterPokemonOverridesCopyWithImpl(this._self, this._then);

  final _ProjectEncounterPokemonOverrides _self;
  final $Res Function(_ProjectEncounterPokemonOverrides) _then;

/// Create a copy of ProjectEncounterPokemonOverrides
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? natureId = freezed,Object? abilityId = freezed,Object? gender = freezed,Object? ivs = freezed,Object? shinyPolicy = null,Object? knownMoveIds = null,}) {
  return _then(_ProjectEncounterPokemonOverrides(
natureId: freezed == natureId ? _self.natureId : natureId // ignore: cast_nullable_to_non_nullable
as String?,abilityId: freezed == abilityId ? _self.abilityId : abilityId // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,ivs: freezed == ivs ? _self.ivs : ivs // ignore: cast_nullable_to_non_nullable
as PokemonStatSpread?,shinyPolicy: null == shinyPolicy ? _self.shinyPolicy : shinyPolicy // ignore: cast_nullable_to_non_nullable
as ProjectEncounterShinyPolicy,knownMoveIds: null == knownMoveIds ? _self._knownMoveIds : knownMoveIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ProjectEncounterPokemonOverrides
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PokemonStatSpreadCopyWith<$Res>? get ivs {
    if (_self.ivs == null) {
    return null;
  }

  return $PokemonStatSpreadCopyWith<$Res>(_self.ivs!, (value) {
    return _then(_self.copyWith(ivs: value));
  });
}
}


/// @nodoc
mixin _$ProjectEncounterEntry {

/// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
 String get speciesId; int get minLevel; int get maxLevel;/// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
 int get weight;@JsonKey(includeIfNull: false) ProjectEncounterPokemonOverrides? get pokemonOverrides;
/// Create a copy of ProjectEncounterEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectEncounterEntryCopyWith<ProjectEncounterEntry> get copyWith => _$ProjectEncounterEntryCopyWithImpl<ProjectEncounterEntry>(this as ProjectEncounterEntry, _$identity);

  /// Serializes this ProjectEncounterEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectEncounterEntry&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.minLevel, minLevel) || other.minLevel == minLevel)&&(identical(other.maxLevel, maxLevel) || other.maxLevel == maxLevel)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.pokemonOverrides, pokemonOverrides) || other.pokemonOverrides == pokemonOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,speciesId,minLevel,maxLevel,weight,pokemonOverrides);

@override
String toString() {
  return 'ProjectEncounterEntry(speciesId: $speciesId, minLevel: $minLevel, maxLevel: $maxLevel, weight: $weight, pokemonOverrides: $pokemonOverrides)';
}


}

/// @nodoc
abstract mixin class $ProjectEncounterEntryCopyWith<$Res>  {
  factory $ProjectEncounterEntryCopyWith(ProjectEncounterEntry value, $Res Function(ProjectEncounterEntry) _then) = _$ProjectEncounterEntryCopyWithImpl;
@useResult
$Res call({
 String speciesId, int minLevel, int maxLevel, int weight,@JsonKey(includeIfNull: false) ProjectEncounterPokemonOverrides? pokemonOverrides
});


$ProjectEncounterPokemonOverridesCopyWith<$Res>? get pokemonOverrides;

}
/// @nodoc
class _$ProjectEncounterEntryCopyWithImpl<$Res>
    implements $ProjectEncounterEntryCopyWith<$Res> {
  _$ProjectEncounterEntryCopyWithImpl(this._self, this._then);

  final ProjectEncounterEntry _self;
  final $Res Function(ProjectEncounterEntry) _then;

/// Create a copy of ProjectEncounterEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? speciesId = null,Object? minLevel = null,Object? maxLevel = null,Object? weight = null,Object? pokemonOverrides = freezed,}) {
  return _then(_self.copyWith(
speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String,minLevel: null == minLevel ? _self.minLevel : minLevel // ignore: cast_nullable_to_non_nullable
as int,maxLevel: null == maxLevel ? _self.maxLevel : maxLevel // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,pokemonOverrides: freezed == pokemonOverrides ? _self.pokemonOverrides : pokemonOverrides // ignore: cast_nullable_to_non_nullable
as ProjectEncounterPokemonOverrides?,
  ));
}
/// Create a copy of ProjectEncounterEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectEncounterPokemonOverridesCopyWith<$Res>? get pokemonOverrides {
    if (_self.pokemonOverrides == null) {
    return null;
  }

  return $ProjectEncounterPokemonOverridesCopyWith<$Res>(_self.pokemonOverrides!, (value) {
    return _then(_self.copyWith(pokemonOverrides: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectEncounterEntry].
extension ProjectEncounterEntryPatterns on ProjectEncounterEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectEncounterEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectEncounterEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectEncounterEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectEncounterEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectEncounterEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectEncounterEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String speciesId,  int minLevel,  int maxLevel,  int weight, @JsonKey(includeIfNull: false)  ProjectEncounterPokemonOverrides? pokemonOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectEncounterEntry() when $default != null:
return $default(_that.speciesId,_that.minLevel,_that.maxLevel,_that.weight,_that.pokemonOverrides);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String speciesId,  int minLevel,  int maxLevel,  int weight, @JsonKey(includeIfNull: false)  ProjectEncounterPokemonOverrides? pokemonOverrides)  $default,) {final _that = this;
switch (_that) {
case _ProjectEncounterEntry():
return $default(_that.speciesId,_that.minLevel,_that.maxLevel,_that.weight,_that.pokemonOverrides);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String speciesId,  int minLevel,  int maxLevel,  int weight, @JsonKey(includeIfNull: false)  ProjectEncounterPokemonOverrides? pokemonOverrides)?  $default,) {final _that = this;
switch (_that) {
case _ProjectEncounterEntry() when $default != null:
return $default(_that.speciesId,_that.minLevel,_that.maxLevel,_that.weight,_that.pokemonOverrides);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectEncounterEntry implements ProjectEncounterEntry {
  const _ProjectEncounterEntry({required this.speciesId, required this.minLevel, required this.maxLevel, this.weight = 1, @JsonKey(includeIfNull: false) this.pokemonOverrides});
  factory _ProjectEncounterEntry.fromJson(Map<String, dynamic> json) => _$ProjectEncounterEntryFromJson(json);

/// Identifiant de l'espèce (string libre — sans Pokédex intégré pour l'instant).
@override final  String speciesId;
@override final  int minLevel;
@override final  int maxLevel;
/// Poids relatif d'apparition (entier positif ; plus élevé = plus fréquent).
@override@JsonKey() final  int weight;
@override@JsonKey(includeIfNull: false) final  ProjectEncounterPokemonOverrides? pokemonOverrides;

/// Create a copy of ProjectEncounterEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectEncounterEntryCopyWith<_ProjectEncounterEntry> get copyWith => __$ProjectEncounterEntryCopyWithImpl<_ProjectEncounterEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectEncounterEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectEncounterEntry&&(identical(other.speciesId, speciesId) || other.speciesId == speciesId)&&(identical(other.minLevel, minLevel) || other.minLevel == minLevel)&&(identical(other.maxLevel, maxLevel) || other.maxLevel == maxLevel)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.pokemonOverrides, pokemonOverrides) || other.pokemonOverrides == pokemonOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,speciesId,minLevel,maxLevel,weight,pokemonOverrides);

@override
String toString() {
  return 'ProjectEncounterEntry(speciesId: $speciesId, minLevel: $minLevel, maxLevel: $maxLevel, weight: $weight, pokemonOverrides: $pokemonOverrides)';
}


}

/// @nodoc
abstract mixin class _$ProjectEncounterEntryCopyWith<$Res> implements $ProjectEncounterEntryCopyWith<$Res> {
  factory _$ProjectEncounterEntryCopyWith(_ProjectEncounterEntry value, $Res Function(_ProjectEncounterEntry) _then) = __$ProjectEncounterEntryCopyWithImpl;
@override @useResult
$Res call({
 String speciesId, int minLevel, int maxLevel, int weight,@JsonKey(includeIfNull: false) ProjectEncounterPokemonOverrides? pokemonOverrides
});


@override $ProjectEncounterPokemonOverridesCopyWith<$Res>? get pokemonOverrides;

}
/// @nodoc
class __$ProjectEncounterEntryCopyWithImpl<$Res>
    implements _$ProjectEncounterEntryCopyWith<$Res> {
  __$ProjectEncounterEntryCopyWithImpl(this._self, this._then);

  final _ProjectEncounterEntry _self;
  final $Res Function(_ProjectEncounterEntry) _then;

/// Create a copy of ProjectEncounterEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? speciesId = null,Object? minLevel = null,Object? maxLevel = null,Object? weight = null,Object? pokemonOverrides = freezed,}) {
  return _then(_ProjectEncounterEntry(
speciesId: null == speciesId ? _self.speciesId : speciesId // ignore: cast_nullable_to_non_nullable
as String,minLevel: null == minLevel ? _self.minLevel : minLevel // ignore: cast_nullable_to_non_nullable
as int,maxLevel: null == maxLevel ? _self.maxLevel : maxLevel // ignore: cast_nullable_to_non_nullable
as int,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,pokemonOverrides: freezed == pokemonOverrides ? _self.pokemonOverrides : pokemonOverrides // ignore: cast_nullable_to_non_nullable
as ProjectEncounterPokemonOverrides?,
  ));
}

/// Create a copy of ProjectEncounterEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectEncounterPokemonOverridesCopyWith<$Res>? get pokemonOverrides {
    if (_self.pokemonOverrides == null) {
    return null;
  }

  return $ProjectEncounterPokemonOverridesCopyWith<$Res>(_self.pokemonOverrides!, (value) {
    return _then(_self.copyWith(pokemonOverrides: value));
  });
}
}


/// @nodoc
mixin _$ProjectEncounterTable {

 String get id; String get name; EncounterKind get encounterKind;/// Probability of attempting this table after one eligible movement step.
///
/// The runtime consumes this authored value. Tests may still provide an
/// explicit policy override, but production must not replace it with a
/// hard-coded rate.
 double get chancePerStep;/// All conditions must evaluate against the current persisted [GameState]
/// before a roll can occur.
 List<ScriptCondition> get conditions; List<ProjectEncounterEntry> get entries; List<String> get tags;
/// Create a copy of ProjectEncounterTable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectEncounterTableCopyWith<ProjectEncounterTable> get copyWith => _$ProjectEncounterTableCopyWithImpl<ProjectEncounterTable>(this as ProjectEncounterTable, _$identity);

  /// Serializes this ProjectEncounterTable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectEncounterTable&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.encounterKind, encounterKind) || other.encounterKind == encounterKind)&&(identical(other.chancePerStep, chancePerStep) || other.chancePerStep == chancePerStep)&&const DeepCollectionEquality().equals(other.conditions, conditions)&&const DeepCollectionEquality().equals(other.entries, entries)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,encounterKind,chancePerStep,const DeepCollectionEquality().hash(conditions),const DeepCollectionEquality().hash(entries),const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'ProjectEncounterTable(id: $id, name: $name, encounterKind: $encounterKind, chancePerStep: $chancePerStep, conditions: $conditions, entries: $entries, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ProjectEncounterTableCopyWith<$Res>  {
  factory $ProjectEncounterTableCopyWith(ProjectEncounterTable value, $Res Function(ProjectEncounterTable) _then) = _$ProjectEncounterTableCopyWithImpl;
@useResult
$Res call({
 String id, String name, EncounterKind encounterKind, double chancePerStep, List<ScriptCondition> conditions, List<ProjectEncounterEntry> entries, List<String> tags
});




}
/// @nodoc
class _$ProjectEncounterTableCopyWithImpl<$Res>
    implements $ProjectEncounterTableCopyWith<$Res> {
  _$ProjectEncounterTableCopyWithImpl(this._self, this._then);

  final ProjectEncounterTable _self;
  final $Res Function(ProjectEncounterTable) _then;

/// Create a copy of ProjectEncounterTable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? encounterKind = null,Object? chancePerStep = null,Object? conditions = null,Object? entries = null,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,encounterKind: null == encounterKind ? _self.encounterKind : encounterKind // ignore: cast_nullable_to_non_nullable
as EncounterKind,chancePerStep: null == chancePerStep ? _self.chancePerStep : chancePerStep // ignore: cast_nullable_to_non_nullable
as double,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<ScriptCondition>,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<ProjectEncounterEntry>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectEncounterTable].
extension ProjectEncounterTablePatterns on ProjectEncounterTable {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectEncounterTable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectEncounterTable() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectEncounterTable value)  $default,){
final _that = this;
switch (_that) {
case _ProjectEncounterTable():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectEncounterTable value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectEncounterTable() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  EncounterKind encounterKind,  double chancePerStep,  List<ScriptCondition> conditions,  List<ProjectEncounterEntry> entries,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectEncounterTable() when $default != null:
return $default(_that.id,_that.name,_that.encounterKind,_that.chancePerStep,_that.conditions,_that.entries,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  EncounterKind encounterKind,  double chancePerStep,  List<ScriptCondition> conditions,  List<ProjectEncounterEntry> entries,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _ProjectEncounterTable():
return $default(_that.id,_that.name,_that.encounterKind,_that.chancePerStep,_that.conditions,_that.entries,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  EncounterKind encounterKind,  double chancePerStep,  List<ScriptCondition> conditions,  List<ProjectEncounterEntry> entries,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _ProjectEncounterTable() when $default != null:
return $default(_that.id,_that.name,_that.encounterKind,_that.chancePerStep,_that.conditions,_that.entries,_that.tags);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectEncounterTable implements ProjectEncounterTable {
  const _ProjectEncounterTable({required this.id, required this.name, required this.encounterKind, this.chancePerStep = defaultEncounterChancePerStep, final  List<ScriptCondition> conditions = const [], final  List<ProjectEncounterEntry> entries = const [], final  List<String> tags = const []}): _conditions = conditions,_entries = entries,_tags = tags;
  factory _ProjectEncounterTable.fromJson(Map<String, dynamic> json) => _$ProjectEncounterTableFromJson(json);

@override final  String id;
@override final  String name;
@override final  EncounterKind encounterKind;
/// Probability of attempting this table after one eligible movement step.
///
/// The runtime consumes this authored value. Tests may still provide an
/// explicit policy override, but production must not replace it with a
/// hard-coded rate.
@override@JsonKey() final  double chancePerStep;
/// All conditions must evaluate against the current persisted [GameState]
/// before a roll can occur.
 final  List<ScriptCondition> _conditions;
/// All conditions must evaluate against the current persisted [GameState]
/// before a roll can occur.
@override@JsonKey() List<ScriptCondition> get conditions {
  if (_conditions is EqualUnmodifiableListView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conditions);
}

 final  List<ProjectEncounterEntry> _entries;
@override@JsonKey() List<ProjectEncounterEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of ProjectEncounterTable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectEncounterTableCopyWith<_ProjectEncounterTable> get copyWith => __$ProjectEncounterTableCopyWithImpl<_ProjectEncounterTable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectEncounterTableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectEncounterTable&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.encounterKind, encounterKind) || other.encounterKind == encounterKind)&&(identical(other.chancePerStep, chancePerStep) || other.chancePerStep == chancePerStep)&&const DeepCollectionEquality().equals(other._conditions, _conditions)&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,encounterKind,chancePerStep,const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'ProjectEncounterTable(id: $id, name: $name, encounterKind: $encounterKind, chancePerStep: $chancePerStep, conditions: $conditions, entries: $entries, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ProjectEncounterTableCopyWith<$Res> implements $ProjectEncounterTableCopyWith<$Res> {
  factory _$ProjectEncounterTableCopyWith(_ProjectEncounterTable value, $Res Function(_ProjectEncounterTable) _then) = __$ProjectEncounterTableCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, EncounterKind encounterKind, double chancePerStep, List<ScriptCondition> conditions, List<ProjectEncounterEntry> entries, List<String> tags
});




}
/// @nodoc
class __$ProjectEncounterTableCopyWithImpl<$Res>
    implements _$ProjectEncounterTableCopyWith<$Res> {
  __$ProjectEncounterTableCopyWithImpl(this._self, this._then);

  final _ProjectEncounterTable _self;
  final $Res Function(_ProjectEncounterTable) _then;

/// Create a copy of ProjectEncounterTable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? encounterKind = null,Object? chancePerStep = null,Object? conditions = null,Object? entries = null,Object? tags = null,}) {
  return _then(_ProjectEncounterTable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,encounterKind: null == encounterKind ? _self.encounterKind : encounterKind // ignore: cast_nullable_to_non_nullable
as EncounterKind,chancePerStep: null == chancePerStep ? _self.chancePerStep : chancePerStep // ignore: cast_nullable_to_non_nullable
as double,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<ScriptCondition>,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ProjectEncounterEntry>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$ProjectScriptEntry {

 String get id; String get name; ScriptAsset get asset; List<String> get tags;
/// Create a copy of ProjectScriptEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectScriptEntryCopyWith<ProjectScriptEntry> get copyWith => _$ProjectScriptEntryCopyWithImpl<ProjectScriptEntry>(this as ProjectScriptEntry, _$identity);

  /// Serializes this ProjectScriptEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectScriptEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.asset, asset) || other.asset == asset)&&const DeepCollectionEquality().equals(other.tags, tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,asset,const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'ProjectScriptEntry(id: $id, name: $name, asset: $asset, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $ProjectScriptEntryCopyWith<$Res>  {
  factory $ProjectScriptEntryCopyWith(ProjectScriptEntry value, $Res Function(ProjectScriptEntry) _then) = _$ProjectScriptEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, ScriptAsset asset, List<String> tags
});


$ScriptAssetCopyWith<$Res> get asset;

}
/// @nodoc
class _$ProjectScriptEntryCopyWithImpl<$Res>
    implements $ProjectScriptEntryCopyWith<$Res> {
  _$ProjectScriptEntryCopyWithImpl(this._self, this._then);

  final ProjectScriptEntry _self;
  final $Res Function(ProjectScriptEntry) _then;

/// Create a copy of ProjectScriptEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? asset = null,Object? tags = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as ScriptAsset,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of ProjectScriptEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptAssetCopyWith<$Res> get asset {

  return $ScriptAssetCopyWith<$Res>(_self.asset, (value) {
    return _then(_self.copyWith(asset: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProjectScriptEntry].
extension ProjectScriptEntryPatterns on ProjectScriptEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectScriptEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectScriptEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectScriptEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectScriptEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectScriptEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectScriptEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  ScriptAsset asset,  List<String> tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectScriptEntry() when $default != null:
return $default(_that.id,_that.name,_that.asset,_that.tags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  ScriptAsset asset,  List<String> tags)  $default,) {final _that = this;
switch (_that) {
case _ProjectScriptEntry():
return $default(_that.id,_that.name,_that.asset,_that.tags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  ScriptAsset asset,  List<String> tags)?  $default,) {final _that = this;
switch (_that) {
case _ProjectScriptEntry() when $default != null:
return $default(_that.id,_that.name,_that.asset,_that.tags);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectScriptEntry implements ProjectScriptEntry {
  const _ProjectScriptEntry({required this.id, required this.name, required this.asset, final  List<String> tags = const []}): _tags = tags;
  factory _ProjectScriptEntry.fromJson(Map<String, dynamic> json) => _$ProjectScriptEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  ScriptAsset asset;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}


/// Create a copy of ProjectScriptEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectScriptEntryCopyWith<_ProjectScriptEntry> get copyWith => __$ProjectScriptEntryCopyWithImpl<_ProjectScriptEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectScriptEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectScriptEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.asset, asset) || other.asset == asset)&&const DeepCollectionEquality().equals(other._tags, _tags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,asset,const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'ProjectScriptEntry(id: $id, name: $name, asset: $asset, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$ProjectScriptEntryCopyWith<$Res> implements $ProjectScriptEntryCopyWith<$Res> {
  factory _$ProjectScriptEntryCopyWith(_ProjectScriptEntry value, $Res Function(_ProjectScriptEntry) _then) = __$ProjectScriptEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, ScriptAsset asset, List<String> tags
});


@override $ScriptAssetCopyWith<$Res> get asset;

}
/// @nodoc
class __$ProjectScriptEntryCopyWithImpl<$Res>
    implements _$ProjectScriptEntryCopyWith<$Res> {
  __$ProjectScriptEntryCopyWithImpl(this._self, this._then);

  final _ProjectScriptEntry _self;
  final $Res Function(_ProjectScriptEntry) _then;

/// Create a copy of ProjectScriptEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? asset = null,Object? tags = null,}) {
  return _then(_ProjectScriptEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,asset: null == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as ScriptAsset,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of ProjectScriptEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScriptAssetCopyWith<$Res> get asset {

  return $ScriptAssetCopyWith<$Res>(_self.asset, (value) {
    return _then(_self.copyWith(asset: value));
  });
}
}


/// @nodoc
mixin _$ProjectCharacterStudioCatalog {

 List<CharacterPortraitStateDefinition> get portraitStates; List<CharacterCustomAnimationDefinition> get customAnimationDefinitions;
/// Create a copy of ProjectCharacterStudioCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCharacterStudioCatalogCopyWith<ProjectCharacterStudioCatalog> get copyWith => _$ProjectCharacterStudioCatalogCopyWithImpl<ProjectCharacterStudioCatalog>(this as ProjectCharacterStudioCatalog, _$identity);

  /// Serializes this ProjectCharacterStudioCatalog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectCharacterStudioCatalog&&const DeepCollectionEquality().equals(other.portraitStates, portraitStates)&&const DeepCollectionEquality().equals(other.customAnimationDefinitions, customAnimationDefinitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(portraitStates),const DeepCollectionEquality().hash(customAnimationDefinitions));

@override
String toString() {
  return 'ProjectCharacterStudioCatalog(portraitStates: $portraitStates, customAnimationDefinitions: $customAnimationDefinitions)';
}


}

/// @nodoc
abstract mixin class $ProjectCharacterStudioCatalogCopyWith<$Res>  {
  factory $ProjectCharacterStudioCatalogCopyWith(ProjectCharacterStudioCatalog value, $Res Function(ProjectCharacterStudioCatalog) _then) = _$ProjectCharacterStudioCatalogCopyWithImpl;
@useResult
$Res call({
 List<CharacterPortraitStateDefinition> portraitStates, List<CharacterCustomAnimationDefinition> customAnimationDefinitions
});




}
/// @nodoc
class _$ProjectCharacterStudioCatalogCopyWithImpl<$Res>
    implements $ProjectCharacterStudioCatalogCopyWith<$Res> {
  _$ProjectCharacterStudioCatalogCopyWithImpl(this._self, this._then);

  final ProjectCharacterStudioCatalog _self;
  final $Res Function(ProjectCharacterStudioCatalog) _then;

/// Create a copy of ProjectCharacterStudioCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? portraitStates = null,Object? customAnimationDefinitions = null,}) {
  return _then(_self.copyWith(
portraitStates: null == portraitStates ? _self.portraitStates : portraitStates // ignore: cast_nullable_to_non_nullable
as List<CharacterPortraitStateDefinition>,customAnimationDefinitions: null == customAnimationDefinitions ? _self.customAnimationDefinitions : customAnimationDefinitions // ignore: cast_nullable_to_non_nullable
as List<CharacterCustomAnimationDefinition>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectCharacterStudioCatalog].
extension ProjectCharacterStudioCatalogPatterns on ProjectCharacterStudioCatalog {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectCharacterStudioCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectCharacterStudioCatalog() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectCharacterStudioCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ProjectCharacterStudioCatalog():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectCharacterStudioCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectCharacterStudioCatalog() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CharacterPortraitStateDefinition> portraitStates,  List<CharacterCustomAnimationDefinition> customAnimationDefinitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectCharacterStudioCatalog() when $default != null:
return $default(_that.portraitStates,_that.customAnimationDefinitions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CharacterPortraitStateDefinition> portraitStates,  List<CharacterCustomAnimationDefinition> customAnimationDefinitions)  $default,) {final _that = this;
switch (_that) {
case _ProjectCharacterStudioCatalog():
return $default(_that.portraitStates,_that.customAnimationDefinitions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CharacterPortraitStateDefinition> portraitStates,  List<CharacterCustomAnimationDefinition> customAnimationDefinitions)?  $default,) {final _that = this;
switch (_that) {
case _ProjectCharacterStudioCatalog() when $default != null:
return $default(_that.portraitStates,_that.customAnimationDefinitions);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectCharacterStudioCatalog implements ProjectCharacterStudioCatalog {
  const _ProjectCharacterStudioCatalog({final  List<CharacterPortraitStateDefinition> portraitStates = const [], final  List<CharacterCustomAnimationDefinition> customAnimationDefinitions = const []}): _portraitStates = portraitStates,_customAnimationDefinitions = customAnimationDefinitions;
  factory _ProjectCharacterStudioCatalog.fromJson(Map<String, dynamic> json) => _$ProjectCharacterStudioCatalogFromJson(json);

 final  List<CharacterPortraitStateDefinition> _portraitStates;
@override@JsonKey() List<CharacterPortraitStateDefinition> get portraitStates {
  if (_portraitStates is EqualUnmodifiableListView) return _portraitStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_portraitStates);
}

 final  List<CharacterCustomAnimationDefinition> _customAnimationDefinitions;
@override@JsonKey() List<CharacterCustomAnimationDefinition> get customAnimationDefinitions {
  if (_customAnimationDefinitions is EqualUnmodifiableListView) return _customAnimationDefinitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customAnimationDefinitions);
}


/// Create a copy of ProjectCharacterStudioCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCharacterStudioCatalogCopyWith<_ProjectCharacterStudioCatalog> get copyWith => __$ProjectCharacterStudioCatalogCopyWithImpl<_ProjectCharacterStudioCatalog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectCharacterStudioCatalogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectCharacterStudioCatalog&&const DeepCollectionEquality().equals(other._portraitStates, _portraitStates)&&const DeepCollectionEquality().equals(other._customAnimationDefinitions, _customAnimationDefinitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_portraitStates),const DeepCollectionEquality().hash(_customAnimationDefinitions));

@override
String toString() {
  return 'ProjectCharacterStudioCatalog(portraitStates: $portraitStates, customAnimationDefinitions: $customAnimationDefinitions)';
}


}

/// @nodoc
abstract mixin class _$ProjectCharacterStudioCatalogCopyWith<$Res> implements $ProjectCharacterStudioCatalogCopyWith<$Res> {
  factory _$ProjectCharacterStudioCatalogCopyWith(_ProjectCharacterStudioCatalog value, $Res Function(_ProjectCharacterStudioCatalog) _then) = __$ProjectCharacterStudioCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<CharacterPortraitStateDefinition> portraitStates, List<CharacterCustomAnimationDefinition> customAnimationDefinitions
});




}
/// @nodoc
class __$ProjectCharacterStudioCatalogCopyWithImpl<$Res>
    implements _$ProjectCharacterStudioCatalogCopyWith<$Res> {
  __$ProjectCharacterStudioCatalogCopyWithImpl(this._self, this._then);

  final _ProjectCharacterStudioCatalog _self;
  final $Res Function(_ProjectCharacterStudioCatalog) _then;

/// Create a copy of ProjectCharacterStudioCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? portraitStates = null,Object? customAnimationDefinitions = null,}) {
  return _then(_ProjectCharacterStudioCatalog(
portraitStates: null == portraitStates ? _self._portraitStates : portraitStates // ignore: cast_nullable_to_non_nullable
as List<CharacterPortraitStateDefinition>,customAnimationDefinitions: null == customAnimationDefinitions ? _self._customAnimationDefinitions : customAnimationDefinitions // ignore: cast_nullable_to_non_nullable
as List<CharacterCustomAnimationDefinition>,
  ));
}


}


/// @nodoc
mixin _$CharacterPortraitStateDefinition {

 String get id; String get displayName; int get sortOrder;
/// Create a copy of CharacterPortraitStateDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterPortraitStateDefinitionCopyWith<CharacterPortraitStateDefinition> get copyWith => _$CharacterPortraitStateDefinitionCopyWithImpl<CharacterPortraitStateDefinition>(this as CharacterPortraitStateDefinition, _$identity);

  /// Serializes this CharacterPortraitStateDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterPortraitStateDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,sortOrder);

@override
String toString() {
  return 'CharacterPortraitStateDefinition(id: $id, displayName: $displayName, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CharacterPortraitStateDefinitionCopyWith<$Res>  {
  factory $CharacterPortraitStateDefinitionCopyWith(CharacterPortraitStateDefinition value, $Res Function(CharacterPortraitStateDefinition) _then) = _$CharacterPortraitStateDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, int sortOrder
});




}
/// @nodoc
class _$CharacterPortraitStateDefinitionCopyWithImpl<$Res>
    implements $CharacterPortraitStateDefinitionCopyWith<$Res> {
  _$CharacterPortraitStateDefinitionCopyWithImpl(this._self, this._then);

  final CharacterPortraitStateDefinition _self;
  final $Res Function(CharacterPortraitStateDefinition) _then;

/// Create a copy of CharacterPortraitStateDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterPortraitStateDefinition].
extension CharacterPortraitStateDefinitionPatterns on CharacterPortraitStateDefinition {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterPortraitStateDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterPortraitStateDefinition() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterPortraitStateDefinition value)  $default,){
final _that = this;
switch (_that) {
case _CharacterPortraitStateDefinition():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterPortraitStateDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterPortraitStateDefinition() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterPortraitStateDefinition() when $default != null:
return $default(_that.id,_that.displayName,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _CharacterPortraitStateDefinition():
return $default(_that.id,_that.displayName,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _CharacterPortraitStateDefinition() when $default != null:
return $default(_that.id,_that.displayName,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CharacterPortraitStateDefinition implements CharacterPortraitStateDefinition {
  const _CharacterPortraitStateDefinition({required this.id, required this.displayName, this.sortOrder = 0});
  factory _CharacterPortraitStateDefinition.fromJson(Map<String, dynamic> json) => _$CharacterPortraitStateDefinitionFromJson(json);

@override final  String id;
@override final  String displayName;
@override@JsonKey() final  int sortOrder;

/// Create a copy of CharacterPortraitStateDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterPortraitStateDefinitionCopyWith<_CharacterPortraitStateDefinition> get copyWith => __$CharacterPortraitStateDefinitionCopyWithImpl<_CharacterPortraitStateDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterPortraitStateDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterPortraitStateDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,sortOrder);

@override
String toString() {
  return 'CharacterPortraitStateDefinition(id: $id, displayName: $displayName, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CharacterPortraitStateDefinitionCopyWith<$Res> implements $CharacterPortraitStateDefinitionCopyWith<$Res> {
  factory _$CharacterPortraitStateDefinitionCopyWith(_CharacterPortraitStateDefinition value, $Res Function(_CharacterPortraitStateDefinition) _then) = __$CharacterPortraitStateDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, int sortOrder
});




}
/// @nodoc
class __$CharacterPortraitStateDefinitionCopyWithImpl<$Res>
    implements _$CharacterPortraitStateDefinitionCopyWith<$Res> {
  __$CharacterPortraitStateDefinitionCopyWithImpl(this._self, this._then);

  final _CharacterPortraitStateDefinition _self;
  final $Res Function(_CharacterPortraitStateDefinition) _then;

/// Create a copy of CharacterPortraitStateDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? sortOrder = null,}) {
  return _then(_CharacterPortraitStateDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CharacterCustomAnimationDefinition {

 String get id; String get displayName; CharacterCustomAnimationMode get mode; int get sortOrder;
/// Create a copy of CharacterCustomAnimationDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCustomAnimationDefinitionCopyWith<CharacterCustomAnimationDefinition> get copyWith => _$CharacterCustomAnimationDefinitionCopyWithImpl<CharacterCustomAnimationDefinition>(this as CharacterCustomAnimationDefinition, _$identity);

  /// Serializes this CharacterCustomAnimationDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterCustomAnimationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,mode,sortOrder);

@override
String toString() {
  return 'CharacterCustomAnimationDefinition(id: $id, displayName: $displayName, mode: $mode, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CharacterCustomAnimationDefinitionCopyWith<$Res>  {
  factory $CharacterCustomAnimationDefinitionCopyWith(CharacterCustomAnimationDefinition value, $Res Function(CharacterCustomAnimationDefinition) _then) = _$CharacterCustomAnimationDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, CharacterCustomAnimationMode mode, int sortOrder
});




}
/// @nodoc
class _$CharacterCustomAnimationDefinitionCopyWithImpl<$Res>
    implements $CharacterCustomAnimationDefinitionCopyWith<$Res> {
  _$CharacterCustomAnimationDefinitionCopyWithImpl(this._self, this._then);

  final CharacterCustomAnimationDefinition _self;
  final $Res Function(CharacterCustomAnimationDefinition) _then;

/// Create a copy of CharacterCustomAnimationDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? mode = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CharacterCustomAnimationMode,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterCustomAnimationDefinition].
extension CharacterCustomAnimationDefinitionPatterns on CharacterCustomAnimationDefinition {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterCustomAnimationDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterCustomAnimationDefinition() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterCustomAnimationDefinition value)  $default,){
final _that = this;
switch (_that) {
case _CharacterCustomAnimationDefinition():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterCustomAnimationDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterCustomAnimationDefinition() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String displayName,  CharacterCustomAnimationMode mode,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterCustomAnimationDefinition() when $default != null:
return $default(_that.id,_that.displayName,_that.mode,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String displayName,  CharacterCustomAnimationMode mode,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _CharacterCustomAnimationDefinition():
return $default(_that.id,_that.displayName,_that.mode,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String displayName,  CharacterCustomAnimationMode mode,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _CharacterCustomAnimationDefinition() when $default != null:
return $default(_that.id,_that.displayName,_that.mode,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CharacterCustomAnimationDefinition implements CharacterCustomAnimationDefinition {
  const _CharacterCustomAnimationDefinition({required this.id, required this.displayName, required this.mode, this.sortOrder = 0});
  factory _CharacterCustomAnimationDefinition.fromJson(Map<String, dynamic> json) => _$CharacterCustomAnimationDefinitionFromJson(json);

@override final  String id;
@override final  String displayName;
@override final  CharacterCustomAnimationMode mode;
@override@JsonKey() final  int sortOrder;

/// Create a copy of CharacterCustomAnimationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCustomAnimationDefinitionCopyWith<_CharacterCustomAnimationDefinition> get copyWith => __$CharacterCustomAnimationDefinitionCopyWithImpl<_CharacterCustomAnimationDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterCustomAnimationDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterCustomAnimationDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,mode,sortOrder);

@override
String toString() {
  return 'CharacterCustomAnimationDefinition(id: $id, displayName: $displayName, mode: $mode, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CharacterCustomAnimationDefinitionCopyWith<$Res> implements $CharacterCustomAnimationDefinitionCopyWith<$Res> {
  factory _$CharacterCustomAnimationDefinitionCopyWith(_CharacterCustomAnimationDefinition value, $Res Function(_CharacterCustomAnimationDefinition) _then) = __$CharacterCustomAnimationDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, CharacterCustomAnimationMode mode, int sortOrder
});




}
/// @nodoc
class __$CharacterCustomAnimationDefinitionCopyWithImpl<$Res>
    implements _$CharacterCustomAnimationDefinitionCopyWith<$Res> {
  __$CharacterCustomAnimationDefinitionCopyWithImpl(this._self, this._then);

  final _CharacterCustomAnimationDefinition _self;
  final $Res Function(_CharacterCustomAnimationDefinition) _then;

/// Create a copy of CharacterCustomAnimationDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? mode = null,Object? sortOrder = null,}) {
  return _then(_CharacterCustomAnimationDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as CharacterCustomAnimationMode,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CharacterPortraitVariant {

 String get portraitStateId; String get assetId; CharacterPortraitFitMode get fitMode;
/// Create a copy of CharacterPortraitVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterPortraitVariantCopyWith<CharacterPortraitVariant> get copyWith => _$CharacterPortraitVariantCopyWithImpl<CharacterPortraitVariant>(this as CharacterPortraitVariant, _$identity);

  /// Serializes this CharacterPortraitVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterPortraitVariant&&(identical(other.portraitStateId, portraitStateId) || other.portraitStateId == portraitStateId)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.fitMode, fitMode) || other.fitMode == fitMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,portraitStateId,assetId,fitMode);

@override
String toString() {
  return 'CharacterPortraitVariant(portraitStateId: $portraitStateId, assetId: $assetId, fitMode: $fitMode)';
}


}

/// @nodoc
abstract mixin class $CharacterPortraitVariantCopyWith<$Res>  {
  factory $CharacterPortraitVariantCopyWith(CharacterPortraitVariant value, $Res Function(CharacterPortraitVariant) _then) = _$CharacterPortraitVariantCopyWithImpl;
@useResult
$Res call({
 String portraitStateId, String assetId, CharacterPortraitFitMode fitMode
});




}
/// @nodoc
class _$CharacterPortraitVariantCopyWithImpl<$Res>
    implements $CharacterPortraitVariantCopyWith<$Res> {
  _$CharacterPortraitVariantCopyWithImpl(this._self, this._then);

  final CharacterPortraitVariant _self;
  final $Res Function(CharacterPortraitVariant) _then;

/// Create a copy of CharacterPortraitVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? portraitStateId = null,Object? assetId = null,Object? fitMode = null,}) {
  return _then(_self.copyWith(
portraitStateId: null == portraitStateId ? _self.portraitStateId : portraitStateId // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,fitMode: null == fitMode ? _self.fitMode : fitMode // ignore: cast_nullable_to_non_nullable
as CharacterPortraitFitMode,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterPortraitVariant].
extension CharacterPortraitVariantPatterns on CharacterPortraitVariant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterPortraitVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterPortraitVariant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterPortraitVariant value)  $default,){
final _that = this;
switch (_that) {
case _CharacterPortraitVariant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterPortraitVariant value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterPortraitVariant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String portraitStateId,  String assetId,  CharacterPortraitFitMode fitMode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterPortraitVariant() when $default != null:
return $default(_that.portraitStateId,_that.assetId,_that.fitMode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String portraitStateId,  String assetId,  CharacterPortraitFitMode fitMode)  $default,) {final _that = this;
switch (_that) {
case _CharacterPortraitVariant():
return $default(_that.portraitStateId,_that.assetId,_that.fitMode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String portraitStateId,  String assetId,  CharacterPortraitFitMode fitMode)?  $default,) {final _that = this;
switch (_that) {
case _CharacterPortraitVariant() when $default != null:
return $default(_that.portraitStateId,_that.assetId,_that.fitMode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CharacterPortraitVariant implements CharacterPortraitVariant {
  const _CharacterPortraitVariant({required this.portraitStateId, required this.assetId, this.fitMode = CharacterPortraitFitMode.contain});
  factory _CharacterPortraitVariant.fromJson(Map<String, dynamic> json) => _$CharacterPortraitVariantFromJson(json);

@override final  String portraitStateId;
@override final  String assetId;
@override@JsonKey() final  CharacterPortraitFitMode fitMode;

/// Create a copy of CharacterPortraitVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterPortraitVariantCopyWith<_CharacterPortraitVariant> get copyWith => __$CharacterPortraitVariantCopyWithImpl<_CharacterPortraitVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterPortraitVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterPortraitVariant&&(identical(other.portraitStateId, portraitStateId) || other.portraitStateId == portraitStateId)&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.fitMode, fitMode) || other.fitMode == fitMode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,portraitStateId,assetId,fitMode);

@override
String toString() {
  return 'CharacterPortraitVariant(portraitStateId: $portraitStateId, assetId: $assetId, fitMode: $fitMode)';
}


}

/// @nodoc
abstract mixin class _$CharacterPortraitVariantCopyWith<$Res> implements $CharacterPortraitVariantCopyWith<$Res> {
  factory _$CharacterPortraitVariantCopyWith(_CharacterPortraitVariant value, $Res Function(_CharacterPortraitVariant) _then) = __$CharacterPortraitVariantCopyWithImpl;
@override @useResult
$Res call({
 String portraitStateId, String assetId, CharacterPortraitFitMode fitMode
});




}
/// @nodoc
class __$CharacterPortraitVariantCopyWithImpl<$Res>
    implements _$CharacterPortraitVariantCopyWith<$Res> {
  __$CharacterPortraitVariantCopyWithImpl(this._self, this._then);

  final _CharacterPortraitVariant _self;
  final $Res Function(_CharacterPortraitVariant) _then;

/// Create a copy of CharacterPortraitVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? portraitStateId = null,Object? assetId = null,Object? fitMode = null,}) {
  return _then(_CharacterPortraitVariant(
portraitStateId: null == portraitStateId ? _self.portraitStateId : portraitStateId // ignore: cast_nullable_to_non_nullable
as String,assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,fitMode: null == fitMode ? _self.fitMode : fitMode // ignore: cast_nullable_to_non_nullable
as CharacterPortraitFitMode,
  ));
}


}


/// @nodoc
mixin _$ProjectCharacterEntry {

 String get id; String get name; String get tilesetId; int get frameWidth; int get frameHeight;@JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false) List<CharacterPortraitVariant> get portraits; List<CharacterAnimation> get animations;@JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false) List<CharacterCustomAnimationClip> get customAnimations; List<String> get tags; int get sortOrder;
/// Create a copy of ProjectCharacterEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCharacterEntryCopyWith<ProjectCharacterEntry> get copyWith => _$ProjectCharacterEntryCopyWithImpl<ProjectCharacterEntry>(this as ProjectCharacterEntry, _$identity);

  /// Serializes this ProjectCharacterEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectCharacterEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.frameWidth, frameWidth) || other.frameWidth == frameWidth)&&(identical(other.frameHeight, frameHeight) || other.frameHeight == frameHeight)&&const DeepCollectionEquality().equals(other.portraits, portraits)&&const DeepCollectionEquality().equals(other.animations, animations)&&const DeepCollectionEquality().equals(other.customAnimations, customAnimations)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tilesetId,frameWidth,frameHeight,const DeepCollectionEquality().hash(portraits),const DeepCollectionEquality().hash(animations),const DeepCollectionEquality().hash(customAnimations),const DeepCollectionEquality().hash(tags),sortOrder);

@override
String toString() {
  return 'ProjectCharacterEntry(id: $id, name: $name, tilesetId: $tilesetId, frameWidth: $frameWidth, frameHeight: $frameHeight, portraits: $portraits, animations: $animations, customAnimations: $customAnimations, tags: $tags, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProjectCharacterEntryCopyWith<$Res>  {
  factory $ProjectCharacterEntryCopyWith(ProjectCharacterEntry value, $Res Function(ProjectCharacterEntry) _then) = _$ProjectCharacterEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String tilesetId, int frameWidth, int frameHeight,@JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false) List<CharacterPortraitVariant> portraits, List<CharacterAnimation> animations,@JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false) List<CharacterCustomAnimationClip> customAnimations, List<String> tags, int sortOrder
});




}
/// @nodoc
class _$ProjectCharacterEntryCopyWithImpl<$Res>
    implements $ProjectCharacterEntryCopyWith<$Res> {
  _$ProjectCharacterEntryCopyWithImpl(this._self, this._then);

  final ProjectCharacterEntry _self;
  final $Res Function(ProjectCharacterEntry) _then;

/// Create a copy of ProjectCharacterEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? tilesetId = null,Object? frameWidth = null,Object? frameHeight = null,Object? portraits = null,Object? animations = null,Object? customAnimations = null,Object? tags = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,frameWidth: null == frameWidth ? _self.frameWidth : frameWidth // ignore: cast_nullable_to_non_nullable
as int,frameHeight: null == frameHeight ? _self.frameHeight : frameHeight // ignore: cast_nullable_to_non_nullable
as int,portraits: null == portraits ? _self.portraits : portraits // ignore: cast_nullable_to_non_nullable
as List<CharacterPortraitVariant>,animations: null == animations ? _self.animations : animations // ignore: cast_nullable_to_non_nullable
as List<CharacterAnimation>,customAnimations: null == customAnimations ? _self.customAnimations : customAnimations // ignore: cast_nullable_to_non_nullable
as List<CharacterCustomAnimationClip>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectCharacterEntry].
extension ProjectCharacterEntryPatterns on ProjectCharacterEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectCharacterEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectCharacterEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectCharacterEntry value)  $default,){
final _that = this;
switch (_that) {
case _ProjectCharacterEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectCharacterEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectCharacterEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String tilesetId,  int frameWidth,  int frameHeight, @JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false)  List<CharacterPortraitVariant> portraits,  List<CharacterAnimation> animations, @JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false)  List<CharacterCustomAnimationClip> customAnimations,  List<String> tags,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectCharacterEntry() when $default != null:
return $default(_that.id,_that.name,_that.tilesetId,_that.frameWidth,_that.frameHeight,_that.portraits,_that.animations,_that.customAnimations,_that.tags,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String tilesetId,  int frameWidth,  int frameHeight, @JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false)  List<CharacterPortraitVariant> portraits,  List<CharacterAnimation> animations, @JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false)  List<CharacterCustomAnimationClip> customAnimations,  List<String> tags,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProjectCharacterEntry():
return $default(_that.id,_that.name,_that.tilesetId,_that.frameWidth,_that.frameHeight,_that.portraits,_that.animations,_that.customAnimations,_that.tags,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String tilesetId,  int frameWidth,  int frameHeight, @JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false)  List<CharacterPortraitVariant> portraits,  List<CharacterAnimation> animations, @JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false)  List<CharacterCustomAnimationClip> customAnimations,  List<String> tags,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProjectCharacterEntry() when $default != null:
return $default(_that.id,_that.name,_that.tilesetId,_that.frameWidth,_that.frameHeight,_that.portraits,_that.animations,_that.customAnimations,_that.tags,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ProjectCharacterEntry implements ProjectCharacterEntry {
  const _ProjectCharacterEntry({required this.id, required this.name, required this.tilesetId, this.frameWidth = 1, this.frameHeight = 2, @JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false) final  List<CharacterPortraitVariant> portraits = const [], final  List<CharacterAnimation> animations = const [], @JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false) final  List<CharacterCustomAnimationClip> customAnimations = const [], final  List<String> tags = const [], this.sortOrder = 0}): _portraits = portraits,_animations = animations,_customAnimations = customAnimations,_tags = tags;
  factory _ProjectCharacterEntry.fromJson(Map<String, dynamic> json) => _$ProjectCharacterEntryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String tilesetId;
@override@JsonKey() final  int frameWidth;
@override@JsonKey() final  int frameHeight;
 final  List<CharacterPortraitVariant> _portraits;
@override@JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false) List<CharacterPortraitVariant> get portraits {
  if (_portraits is EqualUnmodifiableListView) return _portraits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_portraits);
}

 final  List<CharacterAnimation> _animations;
@override@JsonKey() List<CharacterAnimation> get animations {
  if (_animations is EqualUnmodifiableListView) return _animations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_animations);
}

 final  List<CharacterCustomAnimationClip> _customAnimations;
@override@JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false) List<CharacterCustomAnimationClip> get customAnimations {
  if (_customAnimations is EqualUnmodifiableListView) return _customAnimations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customAnimations);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int sortOrder;

/// Create a copy of ProjectCharacterEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectCharacterEntryCopyWith<_ProjectCharacterEntry> get copyWith => __$ProjectCharacterEntryCopyWithImpl<_ProjectCharacterEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectCharacterEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectCharacterEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tilesetId, tilesetId) || other.tilesetId == tilesetId)&&(identical(other.frameWidth, frameWidth) || other.frameWidth == frameWidth)&&(identical(other.frameHeight, frameHeight) || other.frameHeight == frameHeight)&&const DeepCollectionEquality().equals(other._portraits, _portraits)&&const DeepCollectionEquality().equals(other._animations, _animations)&&const DeepCollectionEquality().equals(other._customAnimations, _customAnimations)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,tilesetId,frameWidth,frameHeight,const DeepCollectionEquality().hash(_portraits),const DeepCollectionEquality().hash(_animations),const DeepCollectionEquality().hash(_customAnimations),const DeepCollectionEquality().hash(_tags),sortOrder);

@override
String toString() {
  return 'ProjectCharacterEntry(id: $id, name: $name, tilesetId: $tilesetId, frameWidth: $frameWidth, frameHeight: $frameHeight, portraits: $portraits, animations: $animations, customAnimations: $customAnimations, tags: $tags, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProjectCharacterEntryCopyWith<$Res> implements $ProjectCharacterEntryCopyWith<$Res> {
  factory _$ProjectCharacterEntryCopyWith(_ProjectCharacterEntry value, $Res Function(_ProjectCharacterEntry) _then) = __$ProjectCharacterEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String tilesetId, int frameWidth, int frameHeight,@JsonKey(toJson: _characterPortraitsToJson, includeIfNull: false) List<CharacterPortraitVariant> portraits, List<CharacterAnimation> animations,@JsonKey(toJson: _characterCustomAnimationsToJson, includeIfNull: false) List<CharacterCustomAnimationClip> customAnimations, List<String> tags, int sortOrder
});




}
/// @nodoc
class __$ProjectCharacterEntryCopyWithImpl<$Res>
    implements _$ProjectCharacterEntryCopyWith<$Res> {
  __$ProjectCharacterEntryCopyWithImpl(this._self, this._then);

  final _ProjectCharacterEntry _self;
  final $Res Function(_ProjectCharacterEntry) _then;

/// Create a copy of ProjectCharacterEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? tilesetId = null,Object? frameWidth = null,Object? frameHeight = null,Object? portraits = null,Object? animations = null,Object? customAnimations = null,Object? tags = null,Object? sortOrder = null,}) {
  return _then(_ProjectCharacterEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tilesetId: null == tilesetId ? _self.tilesetId : tilesetId // ignore: cast_nullable_to_non_nullable
as String,frameWidth: null == frameWidth ? _self.frameWidth : frameWidth // ignore: cast_nullable_to_non_nullable
as int,frameHeight: null == frameHeight ? _self.frameHeight : frameHeight // ignore: cast_nullable_to_non_nullable
as int,portraits: null == portraits ? _self._portraits : portraits // ignore: cast_nullable_to_non_nullable
as List<CharacterPortraitVariant>,animations: null == animations ? _self._animations : animations // ignore: cast_nullable_to_non_nullable
as List<CharacterAnimation>,customAnimations: null == customAnimations ? _self._customAnimations : customAnimations // ignore: cast_nullable_to_non_nullable
as List<CharacterCustomAnimationClip>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CharacterAnimation {

 CharacterAnimationState get state; EntityFacing get direction;@JsonKey(includeIfNull: false) String? get sourceAssetId; List<CharacterAnimationFrame> get frames;@JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false) bool get loop;
/// Create a copy of CharacterAnimation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterAnimationCopyWith<CharacterAnimation> get copyWith => _$CharacterAnimationCopyWithImpl<CharacterAnimation>(this as CharacterAnimation, _$identity);

  /// Serializes this CharacterAnimation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterAnimation&&(identical(other.state, state) || other.state == state)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.sourceAssetId, sourceAssetId) || other.sourceAssetId == sourceAssetId)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.loop, loop) || other.loop == loop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,direction,sourceAssetId,const DeepCollectionEquality().hash(frames),loop);

@override
String toString() {
  return 'CharacterAnimation(state: $state, direction: $direction, sourceAssetId: $sourceAssetId, frames: $frames, loop: $loop)';
}


}

/// @nodoc
abstract mixin class $CharacterAnimationCopyWith<$Res>  {
  factory $CharacterAnimationCopyWith(CharacterAnimation value, $Res Function(CharacterAnimation) _then) = _$CharacterAnimationCopyWithImpl;
@useResult
$Res call({
 CharacterAnimationState state, EntityFacing direction,@JsonKey(includeIfNull: false) String? sourceAssetId, List<CharacterAnimationFrame> frames,@JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false) bool loop
});




}
/// @nodoc
class _$CharacterAnimationCopyWithImpl<$Res>
    implements $CharacterAnimationCopyWith<$Res> {
  _$CharacterAnimationCopyWithImpl(this._self, this._then);

  final CharacterAnimation _self;
  final $Res Function(CharacterAnimation) _then;

/// Create a copy of CharacterAnimation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? direction = null,Object? sourceAssetId = freezed,Object? frames = null,Object? loop = null,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as CharacterAnimationState,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as EntityFacing,sourceAssetId: freezed == sourceAssetId ? _self.sourceAssetId : sourceAssetId // ignore: cast_nullable_to_non_nullable
as String?,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<CharacterAnimationFrame>,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterAnimation].
extension CharacterAnimationPatterns on CharacterAnimation {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterAnimation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterAnimation() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterAnimation value)  $default,){
final _that = this;
switch (_that) {
case _CharacterAnimation():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterAnimation value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterAnimation() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CharacterAnimationState state,  EntityFacing direction, @JsonKey(includeIfNull: false)  String? sourceAssetId,  List<CharacterAnimationFrame> frames, @JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false)  bool loop)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterAnimation() when $default != null:
return $default(_that.state,_that.direction,_that.sourceAssetId,_that.frames,_that.loop);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CharacterAnimationState state,  EntityFacing direction, @JsonKey(includeIfNull: false)  String? sourceAssetId,  List<CharacterAnimationFrame> frames, @JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false)  bool loop)  $default,) {final _that = this;
switch (_that) {
case _CharacterAnimation():
return $default(_that.state,_that.direction,_that.sourceAssetId,_that.frames,_that.loop);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CharacterAnimationState state,  EntityFacing direction, @JsonKey(includeIfNull: false)  String? sourceAssetId,  List<CharacterAnimationFrame> frames, @JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false)  bool loop)?  $default,) {final _that = this;
switch (_that) {
case _CharacterAnimation() when $default != null:
return $default(_that.state,_that.direction,_that.sourceAssetId,_that.frames,_that.loop);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CharacterAnimation implements CharacterAnimation {
  const _CharacterAnimation({required this.state, required this.direction, @JsonKey(includeIfNull: false) this.sourceAssetId, final  List<CharacterAnimationFrame> frames = const [], @JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false) this.loop = true}): _frames = frames;
  factory _CharacterAnimation.fromJson(Map<String, dynamic> json) => _$CharacterAnimationFromJson(json);

@override final  CharacterAnimationState state;
@override final  EntityFacing direction;
@override@JsonKey(includeIfNull: false) final  String? sourceAssetId;
 final  List<CharacterAnimationFrame> _frames;
@override@JsonKey() List<CharacterAnimationFrame> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override@JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false) final  bool loop;

/// Create a copy of CharacterAnimation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterAnimationCopyWith<_CharacterAnimation> get copyWith => __$CharacterAnimationCopyWithImpl<_CharacterAnimation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterAnimationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterAnimation&&(identical(other.state, state) || other.state == state)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.sourceAssetId, sourceAssetId) || other.sourceAssetId == sourceAssetId)&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.loop, loop) || other.loop == loop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,state,direction,sourceAssetId,const DeepCollectionEquality().hash(_frames),loop);

@override
String toString() {
  return 'CharacterAnimation(state: $state, direction: $direction, sourceAssetId: $sourceAssetId, frames: $frames, loop: $loop)';
}


}

/// @nodoc
abstract mixin class _$CharacterAnimationCopyWith<$Res> implements $CharacterAnimationCopyWith<$Res> {
  factory _$CharacterAnimationCopyWith(_CharacterAnimation value, $Res Function(_CharacterAnimation) _then) = __$CharacterAnimationCopyWithImpl;
@override @useResult
$Res call({
 CharacterAnimationState state, EntityFacing direction,@JsonKey(includeIfNull: false) String? sourceAssetId, List<CharacterAnimationFrame> frames,@JsonKey(toJson: _characterAnimationLoopToJson, includeIfNull: false) bool loop
});




}
/// @nodoc
class __$CharacterAnimationCopyWithImpl<$Res>
    implements _$CharacterAnimationCopyWith<$Res> {
  __$CharacterAnimationCopyWithImpl(this._self, this._then);

  final _CharacterAnimation _self;
  final $Res Function(_CharacterAnimation) _then;

/// Create a copy of CharacterAnimation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? direction = null,Object? sourceAssetId = freezed,Object? frames = null,Object? loop = null,}) {
  return _then(_CharacterAnimation(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as CharacterAnimationState,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as EntityFacing,sourceAssetId: freezed == sourceAssetId ? _self.sourceAssetId : sourceAssetId // ignore: cast_nullable_to_non_nullable
as String?,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<CharacterAnimationFrame>,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CharacterCustomAnimationClip {

 String get definitionId;@JsonKey(includeIfNull: false) EntityFacing? get direction; String get sourceAssetId; List<CharacterAnimationFrame> get frames; bool get loop;
/// Create a copy of CharacterCustomAnimationClip
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCustomAnimationClipCopyWith<CharacterCustomAnimationClip> get copyWith => _$CharacterCustomAnimationClipCopyWithImpl<CharacterCustomAnimationClip>(this as CharacterCustomAnimationClip, _$identity);

  /// Serializes this CharacterCustomAnimationClip to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterCustomAnimationClip&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.sourceAssetId, sourceAssetId) || other.sourceAssetId == sourceAssetId)&&const DeepCollectionEquality().equals(other.frames, frames)&&(identical(other.loop, loop) || other.loop == loop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,direction,sourceAssetId,const DeepCollectionEquality().hash(frames),loop);

@override
String toString() {
  return 'CharacterCustomAnimationClip(definitionId: $definitionId, direction: $direction, sourceAssetId: $sourceAssetId, frames: $frames, loop: $loop)';
}


}

/// @nodoc
abstract mixin class $CharacterCustomAnimationClipCopyWith<$Res>  {
  factory $CharacterCustomAnimationClipCopyWith(CharacterCustomAnimationClip value, $Res Function(CharacterCustomAnimationClip) _then) = _$CharacterCustomAnimationClipCopyWithImpl;
@useResult
$Res call({
 String definitionId,@JsonKey(includeIfNull: false) EntityFacing? direction, String sourceAssetId, List<CharacterAnimationFrame> frames, bool loop
});




}
/// @nodoc
class _$CharacterCustomAnimationClipCopyWithImpl<$Res>
    implements $CharacterCustomAnimationClipCopyWith<$Res> {
  _$CharacterCustomAnimationClipCopyWithImpl(this._self, this._then);

  final CharacterCustomAnimationClip _self;
  final $Res Function(CharacterCustomAnimationClip) _then;

/// Create a copy of CharacterCustomAnimationClip
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? definitionId = null,Object? direction = freezed,Object? sourceAssetId = null,Object? frames = null,Object? loop = null,}) {
  return _then(_self.copyWith(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as EntityFacing?,sourceAssetId: null == sourceAssetId ? _self.sourceAssetId : sourceAssetId // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self.frames : frames // ignore: cast_nullable_to_non_nullable
as List<CharacterAnimationFrame>,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterCustomAnimationClip].
extension CharacterCustomAnimationClipPatterns on CharacterCustomAnimationClip {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterCustomAnimationClip value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterCustomAnimationClip() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterCustomAnimationClip value)  $default,){
final _that = this;
switch (_that) {
case _CharacterCustomAnimationClip():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterCustomAnimationClip value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterCustomAnimationClip() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String definitionId, @JsonKey(includeIfNull: false)  EntityFacing? direction,  String sourceAssetId,  List<CharacterAnimationFrame> frames,  bool loop)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterCustomAnimationClip() when $default != null:
return $default(_that.definitionId,_that.direction,_that.sourceAssetId,_that.frames,_that.loop);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String definitionId, @JsonKey(includeIfNull: false)  EntityFacing? direction,  String sourceAssetId,  List<CharacterAnimationFrame> frames,  bool loop)  $default,) {final _that = this;
switch (_that) {
case _CharacterCustomAnimationClip():
return $default(_that.definitionId,_that.direction,_that.sourceAssetId,_that.frames,_that.loop);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String definitionId, @JsonKey(includeIfNull: false)  EntityFacing? direction,  String sourceAssetId,  List<CharacterAnimationFrame> frames,  bool loop)?  $default,) {final _that = this;
switch (_that) {
case _CharacterCustomAnimationClip() when $default != null:
return $default(_that.definitionId,_that.direction,_that.sourceAssetId,_that.frames,_that.loop);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CharacterCustomAnimationClip implements CharacterCustomAnimationClip {
  const _CharacterCustomAnimationClip({required this.definitionId, @JsonKey(includeIfNull: false) this.direction, required this.sourceAssetId, final  List<CharacterAnimationFrame> frames = const [], this.loop = true}): _frames = frames;
  factory _CharacterCustomAnimationClip.fromJson(Map<String, dynamic> json) => _$CharacterCustomAnimationClipFromJson(json);

@override final  String definitionId;
@override@JsonKey(includeIfNull: false) final  EntityFacing? direction;
@override final  String sourceAssetId;
 final  List<CharacterAnimationFrame> _frames;
@override@JsonKey() List<CharacterAnimationFrame> get frames {
  if (_frames is EqualUnmodifiableListView) return _frames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_frames);
}

@override@JsonKey() final  bool loop;

/// Create a copy of CharacterCustomAnimationClip
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCustomAnimationClipCopyWith<_CharacterCustomAnimationClip> get copyWith => __$CharacterCustomAnimationClipCopyWithImpl<_CharacterCustomAnimationClip>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterCustomAnimationClipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterCustomAnimationClip&&(identical(other.definitionId, definitionId) || other.definitionId == definitionId)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.sourceAssetId, sourceAssetId) || other.sourceAssetId == sourceAssetId)&&const DeepCollectionEquality().equals(other._frames, _frames)&&(identical(other.loop, loop) || other.loop == loop));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,definitionId,direction,sourceAssetId,const DeepCollectionEquality().hash(_frames),loop);

@override
String toString() {
  return 'CharacterCustomAnimationClip(definitionId: $definitionId, direction: $direction, sourceAssetId: $sourceAssetId, frames: $frames, loop: $loop)';
}


}

/// @nodoc
abstract mixin class _$CharacterCustomAnimationClipCopyWith<$Res> implements $CharacterCustomAnimationClipCopyWith<$Res> {
  factory _$CharacterCustomAnimationClipCopyWith(_CharacterCustomAnimationClip value, $Res Function(_CharacterCustomAnimationClip) _then) = __$CharacterCustomAnimationClipCopyWithImpl;
@override @useResult
$Res call({
 String definitionId,@JsonKey(includeIfNull: false) EntityFacing? direction, String sourceAssetId, List<CharacterAnimationFrame> frames, bool loop
});




}
/// @nodoc
class __$CharacterCustomAnimationClipCopyWithImpl<$Res>
    implements _$CharacterCustomAnimationClipCopyWith<$Res> {
  __$CharacterCustomAnimationClipCopyWithImpl(this._self, this._then);

  final _CharacterCustomAnimationClip _self;
  final $Res Function(_CharacterCustomAnimationClip) _then;

/// Create a copy of CharacterCustomAnimationClip
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? definitionId = null,Object? direction = freezed,Object? sourceAssetId = null,Object? frames = null,Object? loop = null,}) {
  return _then(_CharacterCustomAnimationClip(
definitionId: null == definitionId ? _self.definitionId : definitionId // ignore: cast_nullable_to_non_nullable
as String,direction: freezed == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as EntityFacing?,sourceAssetId: null == sourceAssetId ? _self.sourceAssetId : sourceAssetId // ignore: cast_nullable_to_non_nullable
as String,frames: null == frames ? _self._frames : frames // ignore: cast_nullable_to_non_nullable
as List<CharacterAnimationFrame>,loop: null == loop ? _self.loop : loop // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$CharacterAnimationFrame {

 TilesetSourceRect get source; int get durationMs;
/// Create a copy of CharacterAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterAnimationFrameCopyWith<CharacterAnimationFrame> get copyWith => _$CharacterAnimationFrameCopyWithImpl<CharacterAnimationFrame>(this as CharacterAnimationFrame, _$identity);

  /// Serializes this CharacterAnimationFrame to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterAnimationFrame&&(identical(other.source, source) || other.source == source)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,durationMs);

@override
String toString() {
  return 'CharacterAnimationFrame(source: $source, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $CharacterAnimationFrameCopyWith<$Res>  {
  factory $CharacterAnimationFrameCopyWith(CharacterAnimationFrame value, $Res Function(CharacterAnimationFrame) _then) = _$CharacterAnimationFrameCopyWithImpl;
@useResult
$Res call({
 TilesetSourceRect source, int durationMs
});


$TilesetSourceRectCopyWith<$Res> get source;

}
/// @nodoc
class _$CharacterAnimationFrameCopyWithImpl<$Res>
    implements $CharacterAnimationFrameCopyWith<$Res> {
  _$CharacterAnimationFrameCopyWithImpl(this._self, this._then);

  final CharacterAnimationFrame _self;
  final $Res Function(CharacterAnimationFrame) _then;

/// Create a copy of CharacterAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? durationMs = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TilesetSourceRect,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CharacterAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TilesetSourceRectCopyWith<$Res> get source {

  return $TilesetSourceRectCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}


/// Adds pattern-matching-related methods to [CharacterAnimationFrame].
extension CharacterAnimationFramePatterns on CharacterAnimationFrame {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterAnimationFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterAnimationFrame() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterAnimationFrame value)  $default,){
final _that = this;
switch (_that) {
case _CharacterAnimationFrame():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterAnimationFrame value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterAnimationFrame() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TilesetSourceRect source,  int durationMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterAnimationFrame() when $default != null:
return $default(_that.source,_that.durationMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TilesetSourceRect source,  int durationMs)  $default,) {final _that = this;
switch (_that) {
case _CharacterAnimationFrame():
return $default(_that.source,_that.durationMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TilesetSourceRect source,  int durationMs)?  $default,) {final _that = this;
switch (_that) {
case _CharacterAnimationFrame() when $default != null:
return $default(_that.source,_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _CharacterAnimationFrame implements CharacterAnimationFrame {
  const _CharacterAnimationFrame({required this.source, this.durationMs = 150});
  factory _CharacterAnimationFrame.fromJson(Map<String, dynamic> json) => _$CharacterAnimationFrameFromJson(json);

@override final  TilesetSourceRect source;
@override@JsonKey() final  int durationMs;

/// Create a copy of CharacterAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterAnimationFrameCopyWith<_CharacterAnimationFrame> get copyWith => __$CharacterAnimationFrameCopyWithImpl<_CharacterAnimationFrame>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CharacterAnimationFrameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterAnimationFrame&&(identical(other.source, source) || other.source == source)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,durationMs);

@override
String toString() {
  return 'CharacterAnimationFrame(source: $source, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class _$CharacterAnimationFrameCopyWith<$Res> implements $CharacterAnimationFrameCopyWith<$Res> {
  factory _$CharacterAnimationFrameCopyWith(_CharacterAnimationFrame value, $Res Function(_CharacterAnimationFrame) _then) = __$CharacterAnimationFrameCopyWithImpl;
@override @useResult
$Res call({
 TilesetSourceRect source, int durationMs
});


@override $TilesetSourceRectCopyWith<$Res> get source;

}
/// @nodoc
class __$CharacterAnimationFrameCopyWithImpl<$Res>
    implements _$CharacterAnimationFrameCopyWith<$Res> {
  __$CharacterAnimationFrameCopyWithImpl(this._self, this._then);

  final _CharacterAnimationFrame _self;
  final $Res Function(_CharacterAnimationFrame) _then;

/// Create a copy of CharacterAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? durationMs = null,}) {
  return _then(_CharacterAnimationFrame(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as TilesetSourceRect,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CharacterAnimationFrame
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TilesetSourceRectCopyWith<$Res> get source {

  return $TilesetSourceRectCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}
}

// dart format on
