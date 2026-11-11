import 'dart:async';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/application/project_visuals_controller.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController controller;
  late WorkspacePublicationWorkflow publication;
  late _ExportBoundary exporter;
  var active = true, connectionBusy = false;
  var draftPrompts = 0, pokemonExits = 0;

  setUp(() async {
    active = true;
    connectionBusy = false;
    draftPrompts = 0;
    pokemonExits = 0;
    port = WorkspaceMemoryPort();
    controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
    exporter = _ExportBoundary();
    final workflow = WorkspaceWorkflow(
      controller: controller,
      isActive: () => active,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      confirmClose: () async {
        draftPrompts++;
        return WorkspaceCloseChoice.cancel;
      },
      flushFocus: () {},
      launchMap: (_, _) async {},
    );
    publication = WorkspacePublicationWorkflow(
      controller: controller,
      workflow: workflow,
      isActive: () => active,
      connectionBusy: () => connectionBusy,
      exporter: () => exporter,
      resources: () => null,
      pokemon: () => null,
    );
  });

  tearDown(() => controller.dispose());

  Future<bool> leavePokemon() async {
    pokemonExits++;
    return true;
  }

  Future<bool> prepare(bool confirmed) => publication.prepareExport(
    confirmPokemonSave: () async => throw StateError('No Pokémon owner'),
    confirmSave: () async => confirmed,
  );

  test(
    'export cleanup blocks every exit before document confirmation',
    () async {
      exporter.operationActive = true;
      expect(await publication.allowClose(leavePokemon: leavePokemon), isFalse);
      expect(pokemonExits, 0);
      expect(draftPrompts, 0);
      exporter.operationActive = false;
      expect(await publication.allowClose(leavePokemon: leavePokemon), isTrue);
      expect(pokemonExits, 1);
      expect(port.writes, 0);
    },
  );

  test(
    'connection and owner refusals stop closing before the draft prompt',
    () async {
      connectionBusy = true;
      expect(await publication.allowClose(leavePokemon: leavePokemon), isFalse);
      expect(pokemonExits, 0);
      connectionBusy = false;
      expect(
        await publication.allowClose(leavePokemon: () async => false),
        isFalse,
      );
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'Conservé'),
      );
      expect(
        await publication.allowClose(
          leavePokemon: leavePokemon,
          leaveLibrary: () async => false,
        ),
        isFalse,
      );
      expect(draftPrompts, 0);
      expect(controller.active!.dirty, isTrue);
    },
  );

  test(
    'an inactive export boundary still preserves the normal dirty guard',
    () async {
      expect(await publication.allowClose(leavePokemon: leavePokemon), isTrue);
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Brouillon conservé'));
      expect(await publication.allowClose(leavePokemon: leavePokemon), isFalse);
      expect(draftPrompts, 1);
      expect(document.dirty, isTrue);
      expect(port.writes, 0);
    },
  );

  test(
    'closing rechecks activity after an asynchronous owner decision',
    () async {
      final gate = Completer<bool>();
      final closing = publication.allowClose(leavePokemon: () => gate.future);
      active = false;
      gate.complete(true);
      expect(await closing, isFalse);
      expect(draftPrompts, 0);
    },
  );

  test('refusing export preparation retains the unsaved native map', () async {
    final document = controller.active!;
    document.commit(document.current.copyWith(name: 'Non publié'));
    expect(await prepare(false), isFalse);
    expect(document.dirty, isTrue);
    expect(document.current.name, 'Non publié');
    expect(port.writes, 0);
  });

  test(
    'accepted preparation saves through the owner and survives a fresh reopen',
    () async {
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'Publié'),
      );
      expect(await prepare(true), isTrue);
      expect(controller.active!.dirty, isFalse);
      expect(port.writes, 1);
      final reopened = MapWorkspaceController(workspaceSession, port);
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.active!.current.name, 'Publié');
    },
  );

  test(
    'a failed owner save blocks export and preserves its draft and error',
    () async {
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'Échec conservé'),
      );
      port.failSave = true;
      expect(await prepare(true), isFalse);
      expect(controller.active!.dirty, isTrue);
      expect(controller.active!.current.name, 'Échec conservé');
      expect(controller.active!.error, isNotNull);
    },
  );

  test(
    'preparation cannot publish after its host closes during confirmation',
    () async {
      controller.active!.commit(
        controller.active!.current.copyWith(name: 'En attente'),
      );
      final prompted = Completer<void>(), choice = Completer<bool>();
      final pending = publication.prepareExport(
        confirmPokemonSave: () async => true,
        confirmSave: () {
          prompted.complete();
          return choice.future;
        },
      );
      await prompted.future;
      active = false;
      choice.complete(true);
      expect(await pending, isFalse);
      expect(port.writes, 0);
      expect(controller.active!.dirty, isTrue);
    },
  );

  test(
    'clean preparation does not ask for a save or rewrite the map',
    () async {
      expect(
        await publication.prepareExport(
          confirmPokemonSave: () async => throw StateError('Unexpected prompt'),
          confirmSave: () async => throw StateError('Unexpected prompt'),
        ),
        isTrue,
      );
      expect(port.writes, 0);
    },
  );

  for (final mapScoped in [false, true]) {
    test(
      'invalid visual text alone guards close and export with mapScope=$mapScoped',
      () async {
        final fixture = await _VisualGuardFixture.open(mapScoped: mapScoped);
        final owner = fixture.owner;
        final document = fixture.maps.active!;
        final source = document.current;
        final history = document.undoToken;
        final original = owner.preview.value;
        final saved = owner.saved;
        final visualReads = fixture.port.visualReads;
        final mapReads = fixture.port.reads;
        final catalogs = fixture.port.catalogs;
        owner.reportInvalid(SpatialVisualParameter.fieldOfViewDegrees, 'abc');
        expect(document.current, same(source));
        expect(document.undoToken, history);
        expect(document.dirty, isFalse);
        expect(fixture.maps.dirty, mapScoped);
        expect(owner.preview.value, same(original));
        expect(fixture.workflow.hasPendingChanges, isTrue);

        expect(await fixture.close(), isFalse);
        expect(fixture.closePrompts, 1);
        fixture.choice = WorkspaceCloseChoice.save;
        expect(await fixture.close(), isFalse);
        expect(fixture.closePrompts, 2);
        expect(await fixture.prepare(), isFalse);
        expect(fixture.savePrompts, 1);
        expect(owner.invalidInputs, {
          SpatialVisualParameter.fieldOfViewDegrees: 'abc',
        });
        expect(owner.saved, same(saved));
        expect(owner.preview.value, same(original));
        expect(owner.error, contains('valeurs invalides'));
        expect(fixture.workflow.hasPendingChanges, isTrue);
        expect(fixture.port.visualWrites, 0);
        expect(fixture.port.writes, 0);
        expect(fixture.port.visualReads, visualReads);
        expect(fixture.port.reads, mapReads);
        expect(fixture.port.catalogs, catalogs);

        owner.clearInvalid(SpatialVisualParameter.fieldOfViewDegrees);
        expect(fixture.workflow.hasPendingChanges, isFalse);
        final corrected = original.set(
          SpatialVisualParameter.fieldOfViewDegrees,
          60,
        );
        owner.edit(corrected);
        expect(await fixture.prepare(), isTrue);
        expect(fixture.savePrompts, 2);
        expect(fixture.workflow.hasPendingChanges, isFalse);
        expect(owner.invalidInputs, isEmpty);
        expect(fixture.port.visualWrites, 1);
        expect(fixture.port.writes, 0);
        expect(fixture.port.visualReads, visualReads);
        expect(fixture.port.reads, mapReads);
        expect(fixture.port.catalogs, catalogs);
        expect(fixture.port.profiles.keys, [
          mapScoped ? document.current.id : 'project',
        ]);
        expect(await fixture.close(), isTrue);
        expect(fixture.closePrompts, 2);

        final reopened = ProjectVisualsController(
          session: workspaceSession,
          port: fixture.port,
        );
        addTearDown(reopened.dispose);
        await reopened.open(map: mapScoped ? workspaceEntries.first : null);
        expect(reopened.preview.value, corrected);
        expect(reopened.dirty, isFalse);
        expect(fixture.port.visualReads, visualReads + 1);
        expect(document.current, same(source));
        expect(document.undoToken, history);
      },
    );

    test(
      'invalid visual text requires explicit discard with mapScope=$mapScoped',
      () async {
        final fixture = await _VisualGuardFixture.open(mapScoped: mapScoped);
        final owner = fixture.owner;
        final original = owner.preview.value;
        owner.reportInvalid(SpatialVisualParameter.fieldOfViewDegrees, 'abc');
        expect(fixture.workflow.hasPendingChanges, isTrue);
        fixture.choice = WorkspaceCloseChoice.discard;
        expect(await fixture.close(), isTrue);
        expect(fixture.closePrompts, 1);
        expect(
          owner.invalidInputs[SpatialVisualParameter.fieldOfViewDegrees],
          'abc',
        );
        expect(owner.preview.value, same(original));
        expect(fixture.port.visualWrites, 0);
        expect(fixture.port.writes, 0);

        owner.discard();
        expect(owner.invalidInputs, isEmpty);
        expect(owner.preview.value, original);
        expect(fixture.workflow.hasPendingChanges, isFalse);
        expect(await fixture.prepare(), isTrue);
        expect(fixture.savePrompts, 0);
        expect(await fixture.close(), isTrue);
        expect(fixture.closePrompts, 1);
        expect(fixture.port.visualWrites, 0);
        expect(fixture.port.writes, 0);
      },
    );
  }
}

final class _VisualGuardFixture {
  _VisualGuardFixture(
    this.port,
    this.maps,
    this.owner, {
    required bool mapScoped,
  }) {
    workflow = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      projectVisuals: () => mapScoped ? null : owner,
      confirmClose: () async {
        closePrompts++;
        return choice;
      },
      flushFocus: () {},
      launchMap: (_, _) async {},
    );
    publication = WorkspacePublicationWorkflow(
      controller: maps,
      workflow: workflow,
      isActive: () => true,
      connectionBusy: () => false,
      exporter: () => null,
      resources: () => null,
      pokemon: () => null,
    );
  }

  final _VisualMaps port;
  final MapWorkspaceController maps;
  final ProjectVisualsController owner;
  late final WorkspaceWorkflow workflow;
  late final WorkspacePublicationWorkflow publication;
  WorkspaceCloseChoice choice = WorkspaceCloseChoice.cancel;
  int closePrompts = 0, savePrompts = 0;

  static Future<_VisualGuardFixture> open({required bool mapScoped}) async {
    final port = _VisualMaps();
    final maps = MapWorkspaceController(workspaceSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    final ProjectVisualsController owner;
    if (mapScoped) {
      owner = maps.weatherDraftFor(maps.active!)!;
      await Future<void>.delayed(Duration.zero);
      expect(owner.saved, isNotNull);
    } else {
      owner = ProjectVisualsController(session: workspaceSession, port: port);
      addTearDown(owner.dispose);
      await owner.open();
    }
    return _VisualGuardFixture(port, maps, owner, mapScoped: mapScoped);
  }

  Future<bool> close() =>
      publication.allowClose(leavePokemon: () async => true);

  Future<bool> prepare() => publication.prepareExport(
    confirmPokemonSave: () async => throw StateError('No Pokémon owner'),
    confirmSave: () async {
      savePrompts++;
      return true;
    },
  );
}

final class _VisualMaps extends WorkspaceMemoryPort
    implements ProjectVisualsPort {
  final profiles = <String, SpatialVisualPatch>{};
  int visualReads = 0, visualWrites = 0;

  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async {
    visualReads++;
    return ProjectVisualsState(
      profile: profiles[map?.id ?? 'project'] ?? SpatialVisualPatch(),
      revision: 'visual-$visualWrites',
    );
  }

  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    profiles[map?.id ?? 'project'] = profile;
    return ProjectVisualsState(
      profile: profile,
      revision: 'visual-${++visualWrites}',
    );
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnimplementedError();
}

class _ExportBoundary extends Fake implements StudioGameExportPort {
  @override
  bool operationActive = false;
}
