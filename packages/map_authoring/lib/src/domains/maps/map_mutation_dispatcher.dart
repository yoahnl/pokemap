import 'dart:async';

import '../../contracts/action_descriptor.dart';
import '../../domains/assets/asset_actions.dart';
import '../../domains/assets/element_actions.dart';
import '../../domains/assets/palette_actions.dart';
import '../../domains/assets/presentation_actions.dart';
import '../../domains/assets/preset_actions.dart';
import '../../domains/assets/tileset_actions.dart';
import '../../domains/assets/visual_organization_actions.dart';
import '../../domains/gameplay/pokemon_catalog_actions.dart';
import '../../domains/gameplay/campaign_content_actions.dart';
import '../../domains/narrative/dialogue_actions.dart';
import '../../domains/narrative/cinematic_actions.dart';
import '../../domains/narrative/event_actions.dart';
import '../../domains/narrative/fact_rule_actions.dart';
import '../../domains/narrative/scene_actions.dart';
import '../../domains/narrative/scenario_actions.dart';
import '../../domains/narrative/script_actions.dart';
import '../../domains/narrative/storyline_actions.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'autotile_actions.dart';
import 'border_actions.dart';
import 'collision_actions.dart';
import 'entity_actions.dart';
import 'environment_actions.dart';
import 'map_lifecycle_actions.dart';
import 'map_lifecycle_adapter.dart';
import 'map_operations_batch.dart';
import 'path_actions.dart';
import 'placed_element_actions.dart';
import 'surface_actions.dart';
import 'smart_tile_catalog_actions.dart';
import 'smart_tile_layer_actions.dart';
import 'terrain_actions.dart';
import 'trigger_zone_actions.dart';
import 'warp_connection_actions.dart';

typedef MapMutationDraftBuilder = FutureOr<AuthoringMutationDraft> Function(
  AuthoringPlanningContext context,
);

final class MapMutationActionRegistration {
  const MapMutationActionRegistration({
    required this.descriptor,
    required this.build,
  });

  final AuthoringActionDescriptor descriptor;
  final MapMutationDraftBuilder build;
}

/// Deterministic action-to-domain-handler registry used by direct and JSONL APIs.
final class MapMutationDispatcher {
  MapMutationDispatcher(Iterable<MapMutationActionRegistration> registrations)
      : _registrations = _validatedRegistrations(registrations);

  factory MapMutationDispatcher.canonical({ArtifactStore? artifactStore}) {
    const lifecycle = MapLifecycleActions();
    const operations = MapOperationsActions();
    const terrain = TerrainActions();
    const path = PathActions();
    const surface = SurfaceActions();
    const smartTileCatalog = SmartTileCatalogActions();
    const smartTileLayers = SmartTileLayerActions();
    const autotile = AutotileActions();
    const border = BorderActions();
    const collision = CollisionActions();
    const entity = EntityActions();
    const environment = EnvironmentActions();
    const placedElement = PlacedElementActions();
    const triggerZone = TriggerZoneActions();
    const warpConnection = WarpConnectionActions();
    final assets = AssetActions(
      artifactStore:
          artifactStore ?? MemoryArtifactStore(maximumArtifactBytes: 64 << 20),
    );
    const tilesets = TilesetActions();
    const visualOrganization = VisualOrganizationActions();
    const palettes = PaletteActions();
    const elements = ElementActions();
    const presets = PresetActions();
    const presentation = PresentationActions();
    const pokemonCatalogs = PokemonCatalogActions();
    const campaignContent = CampaignContentActions();
    const dialogues = DialogueActions();
    const cinematics = CinematicActions();
    const scripts = ScriptActions();
    const scenes = SceneActions();
    const events = EventV2Actions();
    const factsAndRules = FactRuleActions();
    const storylines = StorylineActions();
    const scenarios = ScenarioActions();
    return MapMutationDispatcher([
      for (final descriptor in MapLifecycleActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: lifecycle.build,
        ),
      for (final descriptor in MapOperationsActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: operations.build,
        ),
      for (final descriptor in TerrainActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: terrain.build,
        ),
      for (final descriptor in PathActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: path.build,
        ),
      for (final descriptor in SurfaceActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: surface.build,
        ),
      for (final descriptor in SmartTileCatalogActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: smartTileCatalog.build,
        ),
      for (final descriptor in SmartTileLayerActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: smartTileLayers.build,
        ),
      for (final descriptor in AutotileActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: autotile.build,
        ),
      for (final descriptor in BorderActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: border.build,
        ),
      for (final descriptor in CollisionActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: collision.build,
        ),
      for (final descriptor in EntityActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: entity.build,
        ),
      for (final descriptor in EnvironmentActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: environment.build,
        ),
      for (final descriptor in PlacedElementActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: placedElement.build,
        ),
      for (final descriptor in TriggerZoneActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: triggerZone.build,
        ),
      for (final descriptor in WarpConnectionActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: warpConnection.build,
        ),
      for (final descriptor in AssetActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: assets.build,
        ),
      for (final descriptor in TilesetActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: tilesets.build,
        ),
      for (final descriptor in VisualOrganizationActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: visualOrganization.build,
        ),
      for (final descriptor in PaletteActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: palettes.build,
        ),
      for (final descriptor in ElementActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: elements.build,
        ),
      for (final descriptor in PresetActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: presets.build,
        ),
      for (final descriptor in PresentationActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: presentation.build,
        ),
      for (final descriptor in PokemonCatalogActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: pokemonCatalogs.build,
        ),
      for (final descriptor in CampaignContentActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: campaignContent.build,
        ),
      for (final descriptor in DialogueActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: dialogues.build,
        ),
      for (final descriptor in CinematicActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: cinematics.build,
        ),
      for (final descriptor in ScriptActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: scripts.build,
        ),
      for (final descriptor in SceneActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: scenes.build,
        ),
      for (final descriptor in EventV2Actions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: events.build,
        ),
      for (final descriptor in FactRuleActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: factsAndRules.build,
        ),
      for (final descriptor in StorylineActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: storylines.build,
        ),
      for (final descriptor in ScenarioActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: scenarios.build,
        ),
    ]);
  }

  final Map<String, MapMutationActionRegistration> _registrations;

  List<AuthoringActionDescriptor> get descriptors => List.unmodifiable(
        _registrations.values.map((registration) => registration.descriptor),
      );

  AuthoringActionDescriptor descriptor(String actionId) =>
      _registration(actionId).descriptor;

  FutureOr<AuthoringMutationDraft> build(AuthoringPlanningContext context) =>
      _registration(context.request.actionId).build(context);

  MapMutationActionRegistration _registration(String actionId) {
    final registration = _registrations[actionId];
    if (registration == null) {
      throw MapAuthoringException(
        code: 'map.action_unsupported',
        message: 'The requested map authoring action is unsupported.',
        details: {'actionId': actionId},
      );
    }
    return registration;
  }
}

/// Cross-domain names for new clients. The historical map-prefixed symbols
/// remain source-compatible for Phase 1-4 integrations.
typedef AuthoringMutationDraftBuilder = MapMutationDraftBuilder;
typedef AuthoringMutationActionRegistration = MapMutationActionRegistration;
typedef AuthoringMutationDispatcher = MapMutationDispatcher;

Map<String, MapMutationActionRegistration> _validatedRegistrations(
  Iterable<MapMutationActionRegistration> values,
) {
  final registrations = <String, MapMutationActionRegistration>{};
  for (final registration in values) {
    final previous = registrations[registration.descriptor.id];
    if (previous != null) {
      throw ArgumentError.value(
        registration.descriptor.id,
        'registrations',
        'map mutation action IDs must be unique',
      );
    }
    registrations[registration.descriptor.id] = registration;
  }
  final ordered = registrations.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Map.unmodifiable(Map.fromEntries(ordered));
}
