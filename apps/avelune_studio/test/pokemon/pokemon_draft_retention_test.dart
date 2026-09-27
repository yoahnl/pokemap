import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'an immediate return preserves redo on the previous clean draft',
    () async {
      final port = _SpeciesPort();
      final controller = PokemonWorkspaceController(port, changed: () {});
      await controller.load();
      expect(await controller.selectSpecies('a'), isTrue);
      final firstDraft = controller.selectedDraft!;
      firstDraft.edit(PokemonDocumentFamily.species, (json) {
        json['name'] = 'Modifié';
      });
      firstDraft.undo();
      expect(firstDraft.dirty, isFalse);
      expect(firstDraft.canRedo, isTrue);

      expect(await controller.selectSpecies('b'), isTrue);
      expect(await controller.selectSpecies('a'), isTrue);
      expect(port.loads['a'], 1);
      expect(identical(controller.selectedDraft, firstDraft), isTrue);
      expect(controller.selectedDraft!.canRedo, isTrue);
      controller.dispose();
    },
  );

  test('a third species evicts the oldest clean draft', () async {
    final port = _SpeciesPort();
    final controller = PokemonWorkspaceController(port, changed: () {});
    await controller.load();
    expect(await controller.selectSpecies('a'), isTrue);
    final firstDraft = controller.selectedDraft!;
    firstDraft.edit(PokemonDocumentFamily.species, (json) {
      json['name'] = 'Modifié';
    });
    firstDraft.undo();

    expect(await controller.selectSpecies('b'), isTrue);
    expect(await controller.selectSpecies('c'), isTrue);
    expect(await controller.selectSpecies('a'), isTrue);
    expect(port.loads['a'], 2);
    expect(identical(controller.selectedDraft, firstDraft), isFalse);
    expect(controller.selectedDraft!.canRedo, isFalse);
    controller.dispose();
  });

  test(
    'an inactive dirty draft keeps its edits but releases history',
    () async {
      final port = _SpeciesPort(gateB: Completer<void>());
      final controller = PokemonWorkspaceController(port, changed: () {});
      await controller.load();
      expect(await controller.selectSpecies('a'), isTrue);
      final firstDraft = controller.selectedDraft!;

      final selection = controller.selectSpecies('b');
      firstDraft.edit(PokemonDocumentFamily.species, (json) {
        json['name'] = 'Non sauvegardé';
      });
      port.gateB!.complete();
      expect(await selection, isTrue);

      expect(await controller.selectSpecies('a'), isTrue);
      expect(port.loads['a'], 1);
      expect(
        controller.selectedDraft!.document(
          PokemonDocumentFamily.species,
        )!['name'],
        'Non sauvegardé',
      );
      expect(controller.selectedDraft!.dirty, isTrue);
      expect(controller.selectedDraft!.canUndo, isFalse);
      controller.dispose();
    },
  );
}

final class _SpeciesPort implements PokemonWorkspacePort {
  _SpeciesPort({this.gateB});

  final Completer<void>? gateB;
  final loads = <String, int>{};

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: [_summary('a'), _summary('b'), _summary('c')],
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: [],
    items: {},
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async {
    loads.update(entry.id, (count) => count + 1, ifAbsent: () => 1);
    if (entry.id == 'b') await gateB?.future;
    return PokemonSpeciesBundle(
      species: PokemonDocumentSource(
        family: PokemonDocumentFamily.species,
        relativePath: entry.relativePath,
        bytes: null,
        document: {'id': entry.id, 'name': entry.id},
      ),
      learnset: null,
      evolution: null,
      media: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PokemonSpeciesSummary _summary(String id) => PokemonSpeciesSummary(
  id: id,
  name: id,
  nationalDex: 1,
  generation: 1,
  types: [],
  formIds: [],
  mediaRelativePath: '',
  enabled: true,
  relativePath: '$id.json',
);
