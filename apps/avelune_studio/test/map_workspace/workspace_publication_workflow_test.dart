import 'dart:async';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

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
}

class _ExportBoundary extends Fake implements StudioGameExportPort {
  @override
  bool operationActive = false;
}
