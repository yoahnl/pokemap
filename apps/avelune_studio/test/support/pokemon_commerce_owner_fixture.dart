import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_destination_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

import 'm3_story_fixture.dart';
import 'pokemon_authoring_fixture.dart';

const pokemonGoldenItemsPath =
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json';

Future<void> seedPokemonGoldenItems(M3StoryFixture source) async {
  final target = File(
    '${source.directory.path}/data/pokemon/catalogs/items.json',
  );
  await target.parent.create(recursive: true);
  await File(pokemonGoldenItemsPath).copy(target.path);
}

Future<void> seedPokemonGoldenItemsAndShop(M3StoryFixture source) async {
  await seedPokemonGoldenItems(source);
  await rewritePokemonManifest(
    source.directory,
    (manifest) => manifest.copyWith(
      shops: [const ShopDefinition(id: 'gare', label: 'Boutique de la gare')],
    ),
  );
}

Future<void> rewritePokemonManifest(
  Directory root,
  ProjectManifest Function(ProjectManifest) change,
) async {
  final file = File('${root.path}/project.json');
  final manifest = ProjectManifest.fromJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  await file.writeAsString(jsonEncode(change(manifest).toJson()));
}

Future<PokemonCommerceSnapshot> reopenPokemonCommerce(
  PokemonAuthoringFixture host,
) async {
  final session = ProjectSession(
    sessionId: 'reopened-commerce',
    name: host.source.session.name,
    directoryPath: host.source.directory.path,
    storage: host.source.session.storage,
  );
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(session);
  return LocalPokemonCommerceAdapter(session: session, mapAdapter: maps).load();
}

ProjectItemUseDefinition pokemonItemUse(
  ProjectItemDefinition item,
  ProjectItemUseContext context,
) => item.uses.firstWhere((use) => use.contexts.contains(context));

final class PokemonDestinationRoute {
  PokemonDestinationRoute(this.host) {
    navigation = WorkspaceNavigationSession(
      controller: host.maps,
      isActive: () => !_disposed,
      changed: () {},
    );
    workshops = WorkspaceWorkshopRoutes(
      controller: host.maps,
      isActive: () => !_disposed,
      failed: (failure) => this.failure = failure,
      changed: () {},
    );
    destinations = WorkspaceDestinationWorkflow(
      controller: host.maps,
      navigation: navigation,
      sessions: host.sessions,
      workshops: workshops,
      isActive: () => !_disposed,
      changed: () {},
      leavePokemon: host.workflow.requestLeave,
      flushFocus: () {},
      closeContext: () {},
    );
  }

  final PokemonAuthoringFixture host;
  late final WorkspaceNavigationSession navigation;
  late final WorkspaceWorkshopRoutes workshops;
  late final WorkspaceDestinationWorkflow destinations;
  Object? failure;
  bool _disposed = false;

  Future<void> go(WorkspaceSpace destination) async {
    destinations.show(destination);
    final elapsed = Stopwatch()..start();
    while (navigation.space != destination || workshops.loading) {
      if (failure != null) throw StateError('$failure');
      if (elapsed.elapsed > const Duration(seconds: 20)) {
        throw StateError('Destination $destination was not shown.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    await host.settle();
  }

  void dispose() {
    _disposed = true;
    destinations.dispose();
  }
}

final class RecordingItemCommercePort implements PokemonCommercePort {
  ProjectItemDefinition item = const ProjectItemDefinition(
    id: 'custom_tool',
    displayName: 'Outil',
    pocketId: 'custom',
  );

  @override
  Future<void> saveItem(
    ProjectItemDefinition? before,
    ProjectItemDefinition after,
  ) async {
    item = after;
  }

  @override
  Future<PokemonCommerceSnapshot> load() async => PokemonCommerceSnapshot(
    project: const ProjectManifest(name: 'Items', maps: [], tilesets: []),
    catalog: ProjectItemCatalog(schemaVersion: 1, entries: [item]),
    shops: const [],
    references: ProjectItemReferenceIndex(const []),
    narrativeReferences: NarrativeDependencyIndex(),
    shopDiagnostics: const [],
    catalogPath: 'data/pokemon/catalogs/items.json',
    problem: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
