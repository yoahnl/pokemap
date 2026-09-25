import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('an in-flight PNG import cannot erase concurrent draft input', () async {
    final port = _HeldPokemonPort();
    final controller = PokemonWorkspaceController(port, changed: () {});
    await controller.load();
    expect(await controller.selectSpecies('bulbasaur'), isTrue);
    final operation = controller.importMenuPng(
      sourcePath: '/tmp/icon.png',
      formId: 'base',
      role: 'icon',
    );
    await port.importStarted.future;
    expect(controller.mutationActive, isTrue);
    controller.edit(
      PokemonDocumentFamily.species,
      (json) => (json['names'] as Map)['fr'] = 'Saisie concurrente',
    );
    controller.undo();
    controller.redo();
    controller.discardSelectedSpecies();
    expect(controller.selectedDraft!.dirty, isFalse);
    expect(
      (controller.selectedDraft!.document(
            PokemonDocumentFamily.species,
          )!['names']
          as Map)['fr'],
      'Bulbizarre',
    );
    port.importGate.complete();
    expect(await operation, isTrue);
    expect(controller.mutationActive, isFalse);
    controller.dispose();
  });

  test('undo cannot race a save and resurrect stale values', () async {
    final port = _HeldPokemonPort();
    final controller = PokemonWorkspaceController(port, changed: () {});
    await controller.load();
    await controller.selectSpecies('bulbasaur');
    controller.edit(
      PokemonDocumentFamily.species,
      (json) => (json['names'] as Map)['fr'] = 'Nom sauvé',
    );
    final operation = controller.saveActiveOwner();
    await port.saveStarted.future;
    controller.undo();
    expect(controller.selectedDraft!.dirty, isTrue);
    expect(
      (controller.selectedDraft!.document(
            PokemonDocumentFamily.species,
          )!['names']
          as Map)['fr'],
      'Nom sauvé',
    );
    port.saveGate.complete();
    expect(await operation, isTrue);
    expect(controller.selectedDraft!.dirty, isFalse);
    controller.dispose();
  });

  test('active-owner discard never resets a hidden Commerce draft', () async {
    final port = _HeldPokemonPort();
    final commerce = PokemonCommerceController(
      _UnusedCommercePort(),
      changed: () {},
    );
    final controller = PokemonWorkspaceController(
      port,
      changed: () {},
      commerce: commerce,
    );
    await controller.load();
    await controller.selectSpecies('bulbasaur');
    controller.edit(
      PokemonDocumentFamily.species,
      (json) => (json['names'] as Map)['fr'] = 'Espèce en cours',
    );
    commerce.selectItem(
      const ProjectItemDefinition(
        id: 'potion',
        displayName: 'Potion',
        pocketId: 'items',
      ),
    );
    commerce.editItem((item) => item.copyWith(displayName: 'Objet en cours'));
    expect(await controller.saveActiveOwner(), isFalse);
    expect(port.saveStarted.isCompleted, isFalse);
    expect(controller.discardActiveOwner(), isTrue);
    expect(controller.selectedDraft!.dirty, isFalse);
    expect(commerce.item!.displayName, 'Objet en cours');
    expect(commerce.dirty, isTrue);
    expect(controller.setView(PokemonWorkspaceView.items), isFalse);
    controller.dispose();
  });
}

final class _UnusedCommercePort implements PokemonCommercePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _HeldPokemonPort implements PokemonWorkspacePort {
  final importStarted = Completer<void>();
  final importGate = Completer<void>();
  final saveStarted = Completer<void>();
  final saveGate = Completer<void>();
  String name = 'Bulbizarre';

  static const entry = PokemonSpeciesSummary(
    id: 'bulbasaur',
    name: 'Bulbizarre',
    nationalDex: 1,
    generation: 1,
    types: ['grass'],
    formIds: ['base'],
    mediaRelativePath: '',
    enabled: true,
    relativePath: 'data/pokemon/species/bulbasaur.json',
  );

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async =>
      const PokemonWorkspaceIndex(
        enabled: true,
        entries: [entry],
        moves: PokemonMovesCatalogView(entries: [], relativePath: ''),
        types: ['grass'],
        items: {},
      );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      _bundle(name);

  @override
  Future<String> importMenuPng({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  }) async {
    importStarted.complete();
    await importGate.future;
    return 'PNG associé';
  }

  @override
  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft) async {
    saveStarted.complete();
    await saveGate.future;
    name =
        (draft.document(PokemonDocumentFamily.species)!['names'] as Map)['fr']
            as String;
    return _bundle(name);
  }

  PokemonSpeciesBundle _bundle(String name) => PokemonSpeciesBundle(
    species: PokemonDocumentSource(
      family: PokemonDocumentFamily.species,
      relativePath: entry.relativePath,
      bytes: null,
      document: {
        'id': 'bulbasaur',
        'names': {'fr': name},
      },
    ),
    learnset: null,
    evolution: null,
    media: null,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
