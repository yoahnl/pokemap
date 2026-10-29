import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/features/session/application/services/hub_game_options_availability.dart';

void main() {
  const timePredicate = MapEntityRuntimePredicate(
    kind: MapEntityRuntimePredicateKind.localTimeWindow,
    timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 600),
  );
  const entry = ProjectMapEntry(
    id: 'start',
    name: 'Start',
    relativePath: 'maps/start.json',
  );
  final project = ProjectManifest(name: 'Test', maps: [entry], tilesets: []);
  final emptyMap = MapData(
    id: 'start',
    name: 'Start',
    size: const GridSize(width: 2, height: 2),
  );

  Future<SpatialVisualPatch> noProfile(String? _) async => SpatialVisualPatch();

  test('a 2D game without a clock hides weather, time and 3D', () async {
    final options = await hubGameOptionsAvailability(
      project: project,
      capabilities: const {},
      loadMap: (_) async => emptyMap,
      loadVisualProfile: noProfile,
    );
    expect(options.graphics3d, isFalse);
    expect(options.weather, isFalse);
    expect(options.worldTime, isFalse);
  });

  test('a time-dependent NPC keeps the time option', () async {
    final map = emptyMap.copyWith(
      entities: [
        const MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 0),
          npc: MapEntityNpcData(
            visibilityRule: MapEntityNpcVisibilityRule(
              mode: MapEntityNpcVisibilityMode.visibleWhen,
              predicate: timePredicate,
            ),
          ),
        ),
      ],
    );
    final options = await hubGameOptionsAvailability(
      project: project,
      capabilities: const {},
      loadMap: (_) async => map,
      loadVisualProfile: noProfile,
    );
    expect(options.worldTime, isTrue);
  });

  test(
    'a time-dependent encounter keeps the option without loading maps',
    () async {
      final timedProject = project.copyWith(
        encounterTables: [
          const ProjectEncounterTable(
            id: 'route',
            name: 'Route',
            encounterKind: EncounterKind.walk,
            variants: [
              ProjectEncounterVariant(
                id: 'morning',
                name: 'Morning',
                timeWindows: [
                  LocalTimeWindow(startMinute: 240, endMinute: 600),
                ],
              ),
            ],
          ),
        ],
      );
      final options = await hubGameOptionsAvailability(
        project: timedProject,
        capabilities: const {},
        loadMap: (_) async => throw StateError('map should not be loaded'),
        loadVisualProfile: noProfile,
      );
      expect(options.worldTime, isTrue);
    },
  );

  test('an unreadable map keeps the time option available', () async {
    final options = await hubGameOptionsAvailability(
      project: project,
      capabilities: const {},
      loadMap: (_) async => throw StateError('unavailable'),
      loadVisualProfile: noProfile,
    );
    expect(options.worldTime, isTrue);
    expect(options.graphics3d, isFalse);
    expect(options.weather, isFalse);
  });

  test('partitioned project metadata retains timed encounters', () async {
    final timed = project.copyWith(
      encounterTables: [
        const ProjectEncounterTable(
          id: 'route',
          name: 'Route',
          encounterKind: EncounterKind.walk,
          variants: [
            ProjectEncounterVariant(
              id: 'morning',
              name: 'Morning',
              timeWindows: [LocalTimeWindow(startMinute: 240, endMinute: 600)],
            ),
          ],
        ),
      ],
    );
    final publication = PortableCatalogPublication.encodeProject(timed);
    final catalog = await PortableProjectCatalog.open(
      publication.descriptor,
      readObject: (reference) async =>
          publication.storage.objects[reference.sha256]!,
    );
    final options = await hubGameOptionsAvailability(
      project: catalog.projectMetadata,
      capabilities: const {},
      loadMap: (_) async => throw StateError('map should not be loaded'),
      loadVisualProfile: noProfile,
    );
    expect(options.worldTime, isTrue);
  });

  test('3D capabilities keep real weather and day-night options', () async {
    final options = await hubGameOptionsAvailability(
      project: project.copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ),
      capabilities: const {
        WorldEnvironmentCapabilities.realWeatherCapabilityId,
        SpatialSceneLightingCapabilities.dayNightCapabilityId,
      },
      loadMap: (_) async => throw StateError('map should not be loaded'),
      loadVisualProfile: (_) async =>
          throw StateError('profile should not be loaded'),
    );
    expect(options.graphics3d, isTrue);
    expect(options.weather, isTrue);
    expect(options.worldTime, isTrue);
  });

  test('a 3D profile can enable real weather and a world clock', () async {
    final options = await hubGameOptionsAvailability(
      project: project.copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ),
      capabilities: const {},
      loadMap: (_) async => emptyMap,
      loadVisualProfile: (_) async => SpatialVisualPatch({
        SpatialVisualParameter.weatherMode: WorldWeatherMode.real.name,
        SpatialVisualParameter.timeMode: WorldTimeMode.real.name,
      }),
    );
    expect(options.graphics3d, isTrue);
    expect(options.weather, isTrue);
    expect(options.worldTime, isTrue);
  });
}
