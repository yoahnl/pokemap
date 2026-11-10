import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_workflow.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_moves_snapshot_source.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:map_authoring/map_authoring.dart'
    show PokemonExternalSourceRepository;
import 'package:map_authoring/map_authoring_local.dart' show ProjectFileReader;

import 'm3_story_fixture.dart';

class PokemonAuthoringFixture {
  PokemonAuthoringFixture._(this.source, this.maps, this.sessions, this.port) {
    workflow = PokemonWorkspaceWorkflow(
      current: () => _closed ? null : pokemon,
      isActive: () => !_closed,
      confirmDraft: () async {
        draftConfirmations++;
        return decision;
      },
    );
  }

  final M3StoryFixture source;
  final MapWorkspaceController maps;
  final WorkspaceSessionControllers sessions;
  final LocalPokemonWorkspaceAdapter port;
  late final PokemonWorkspaceWorkflow workflow;
  PokemonDraftDecision decision = PokemonDraftDecision.stay;
  int draftConfirmations = 0;
  bool _closed = false;
  bool _disposed = false;
  Future<void>? _disposal;

  PokemonWorkspaceController get pokemon => sessions.pokemon!;
  PokemonCommerceController get commerce => pokemon.commerce!;
  PokemonCombatController get combat => pokemon.combat!;

  static Future<PokemonAuthoringFixture> create({
    Future<void> Function(M3StoryFixture source)? prepareSource,
    ProjectFileReader? reader,
    PokemonMovesSnapshotSource? movesSource,
    PokemonExternalSourceRepository? externalSource,
  }) async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await root.create(recursive: true);
    final source = await M3StoryFixture.create(parent: root);
    MapWorkspaceController? maps;
    WorkspaceSessionControllers? sessions;
    LocalPokemonWorkspaceAdapter? port;
    try {
      await prepareSource?.call(source);
      maps = MapWorkspaceController(source.session, source.maps);
      await maps.initialize();
      if (maps.error != null) throw StateError(maps.error!);
      port = LocalPokemonWorkspaceAdapter(
        session: source.session,
        mapAdapter: source.maps,
        reader: reader,
        movesSource: movesSource,
        externalSource: externalSource,
      );
      sessions = WorkspaceSessionControllers(
        controller: maps,
        changed: maps.notify,
        visualCatalogChanged: (_) {},
        flushEditors: () async => true,
        pokemonPort: port,
        pokemonCommercePort: LocalPokemonCommerceAdapter(
          session: source.session,
          mapAdapter: source.maps,
        ),
        pokemonCombatPort: LocalPokemonCombatAdapter(
          session: source.session,
          mapAdapter: source.maps,
        ),
      );
      sessions.initializePokemon();
      final fixture = PokemonAuthoringFixture._(source, maps, sessions, port);
      await fixture.pokemon.load();
      return fixture;
    } catch (_) {
      await sessions?.dispose();
      await port?.close();
      maps?.dispose();
      await source.directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<bool> view(PokemonWorkspaceView next) async {
    final changed = await workflow.requestView(next);
    await settle();
    return changed;
  }

  Future<void> settle() async {
    final elapsed = Stopwatch()..start();
    while (pokemon.loading ||
        commerce.loading ||
        combat.loading ||
        combat.analyzing) {
      if (elapsed.elapsed > const Duration(seconds: 20)) {
        throw StateError('Pokemon authoring read did not settle.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> closeOwners() async {
    if (_closed) return;
    _closed = true;
    workflow.dispose();
    await sessions.dispose();
    await port.close();
    maps.dispose();
  }

  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    return _disposal ??= _dispose().whenComplete(() => _disposed = true);
  }

  Future<void> _dispose() async {
    await closeOwners();
    if (await source.directory.exists()) {
      await source.directory.delete(recursive: true);
    }
  }
}
