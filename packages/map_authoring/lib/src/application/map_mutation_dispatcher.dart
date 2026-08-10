import 'dart:async';

import '../contracts/action_descriptor.dart';
import '../domains/assets/asset_actions.dart';
import '../domains/assets/element_actions.dart';
import '../domains/assets/palette_actions.dart';
import '../domains/assets/presentation_actions.dart';
import '../domains/assets/presentation_preset_actions.dart';
import '../domains/assets/tileset_actions.dart';
import '../domains/assets/tiled_tileset_import_actions.dart';
import '../domains/assets/tiled_image_collection_packer.dart';
import '../domains/assets/visual_organization_actions.dart';
import '../domains/gameplay/pokemon_catalog_actions.dart';
import '../domains/gameplay/campaign_content_actions.dart';
import '../domains/narrative/dialogue_actions.dart';
import '../domains/narrative/cinematic_actions.dart';
import '../domains/narrative/event_actions.dart';
import '../domains/narrative/fact_rule_actions.dart';
import '../domains/narrative/scene_actions.dart';
import '../domains/narrative/scenario_actions.dart';
import '../domains/narrative/script_actions.dart';
import '../domains/narrative/storyline_actions.dart';
import '../ports/artifact_store.dart';
import '../registry/mutation_registry.dart';
import '../transactions/action_planner.dart';
import '../transactions/authoring_plan.dart';
import '../domains/maps/border_actions.dart';
import '../domains/maps/collision_actions.dart';
import '../domains/maps/entity_actions.dart';
import '../domains/maps/environment_actions.dart';
import '../domains/maps/map_lifecycle_actions.dart';
import '../domains/maps/map_lifecycle_adapter.dart';
import '../domains/maps/map_operations_batch.dart';
import '../domains/maps/placed_element_actions.dart';
import '../domains/maps/smart_tile_catalog_actions.dart';
import '../domains/maps/smart_tile_cell_actions.dart';
import '../domains/maps/smart_tile_layer_actions.dart';
import '../domains/maps/smart_tile_pattern_actions.dart';
import '../domains/maps/tiled_map_import_actions.dart';
import '../domains/maps/trigger_zone_actions.dart';
import '../domains/maps/warp_connection_actions.dart';

typedef MapMutationDraftBuilder = FutureOr<AuthoringMutationDraft> Function(
  AuthoringPlanningContext context,
);

final class MapMutationActionRegistration {
  MapMutationActionRegistration({
    required this.descriptor,
    required this.build,
    MutationContractEvidence? evidence,
  }) : evidence = evidence ?? _journaledEvidence(descriptor);

  final AuthoringActionDescriptor descriptor;
  final MapMutationDraftBuilder build;
  final MutationContractEvidence evidence;
}

/// Deterministic action-to-domain-handler registry used by direct and JSONL APIs.
final class MapMutationDispatcher {
  MapMutationDispatcher(Iterable<MapMutationActionRegistration> registrations)
      : _registrations = _validatedRegistrations(registrations);

  factory MapMutationDispatcher.canonical({
    ArtifactStore? artifactStore,
    TiledImageCollectionRasterCodec? tiledImageCollectionRasterCodec,
  }) {
    const lifecycle = MapLifecycleActions();
    const operations = MapOperationsActions();
    const smartTileCatalog = SmartTileCatalogActions();
    const smartTileCells = SmartTileCellActions();
    const smartTileLayers = SmartTileLayerActions();
    const smartTilePatterns = SmartTilePatternActions();
    const border = BorderActions();
    const collision = CollisionActions();
    const entity = EntityActions();
    const environment = EnvironmentActions();
    const placedElement = PlacedElementActions();
    const triggerZone = TriggerZoneActions();
    const warpConnection = WarpConnectionActions();
    final artifacts =
        artifactStore ?? MemoryArtifactStore(maximumArtifactBytes: 64 << 20);
    final assets = AssetActions(artifactStore: artifacts);
    final tiledTilesets = TiledTilesetImportActions(
      artifactStore: artifacts,
      imageCollectionRasterCodec: tiledImageCollectionRasterCodec,
    );
    final tiledMaps = TiledMapImportActions(
      artifactStore: artifacts,
      imageCollectionRasterCodec: tiledImageCollectionRasterCodec,
    );
    const tilesets = TilesetActions();
    const visualOrganization = VisualOrganizationActions();
    const palettes = PaletteActions();
    const elements = ElementActions();
    const presentation = PresentationActions();
    final presentationPresets = PresentationPresetActions(
      artifactStore: artifacts,
    );
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
      for (final descriptor in SmartTileCellActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: smartTileCells.build,
        ),
      for (final descriptor in SmartTilePatternActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: smartTilePatterns.build,
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
      for (final descriptor in TiledTilesetImportActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: tiledTilesets.build,
        ),
      for (final descriptor in TiledMapImportActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: tiledMaps.build,
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
      for (final descriptor in PresentationActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: presentation.build,
        ),
      for (final descriptor in PresentationPresetActions.descriptors)
        MapMutationActionRegistration(
          descriptor: descriptor,
          build: presentationPresets.build,
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
  final admission = AuthoringMutationRegistry();
  for (final registration in values) {
    final previous = registrations[registration.descriptor.id];
    if (previous != null) {
      throw ArgumentError.value(
        registration.descriptor.id,
        'registrations',
        'map mutation action IDs must be unique',
      );
    }
    admission.register(
      descriptor: registration.descriptor,
      evidence: registration.evidence,
    );
    registrations[registration.descriptor.id] = registration;
  }
  final ordered = registrations.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Map.unmodifiable(Map.fromEntries(ordered));
}

MutationContractEvidence _journaledEvidence(
  AuthoringActionDescriptor descriptor,
) {
  final guarantees = descriptor.guarantees.toSet();
  return MutationContractEvidence(
    proofs: {
      MutationContractProof.plan,
      MutationContractProof.recovery,
      MutationContractProof.authorization,
      MutationContractProof.receipt,
      if (guarantees.contains(AuthoringGuarantee.dryRun))
        MutationContractProof.dryRun,
      if (guarantees.contains(AuthoringGuarantee.revisionChecked))
        MutationContractProof.staleCas,
      if (guarantees.contains(AuthoringGuarantee.idempotent))
        MutationContractProof.idempotency,
      if (guarantees.contains(AuthoringGuarantee.undoable))
        MutationContractProof.undo,
    },
  );
}
