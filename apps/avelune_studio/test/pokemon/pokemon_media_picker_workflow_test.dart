import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_workflow.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(PokemonWorkspaceController, _MediaPort)> _open() async {
  final port = _MediaPort();
  final controller = PokemonWorkspaceController(port, changed: () {});
  addTearDown(controller.dispose);
  await controller.load();
  await controller.selectSpecies('a');
  return (controller, port);
}

PokemonWorkspaceWorkflow _workflow(
  PokemonWorkspaceController? Function() current,
) {
  final workflow = PokemonWorkspaceWorkflow(
    current: current,
    isActive: () => true,
    confirmDraft: () async => PokemonDraftDecision.stay,
  );
  addTearDown(workflow.dispose);
  return workflow;
}

void main() {
  test('a chosen PNG delegates the exact reviewed species form and role to canonical import', () async {
    final (controller, port) = await _open();
    expect(
      await _workflow(() => controller).chooseMenuPng(
        formId: 'base',
        role: 'icon',
        picker: () async => '/source/icon.png',
        isCurrentSelection: () => true,
      ),
      isTrue,
    );
    expect(port.imports, [('a', 'base', 'icon', '/source/icon.png')]);
  });

  test('a cancelled PNG picker leaves every media role untouched', () async {
    final (controller, port) = await _open();
    expect(
      await _workflow(() => controller).chooseMenuPng(
        formId: 'base',
        role: 'icon',
        picker: () async => null,
        isCurrentSelection: () => true,
      ),
      isFalse,
    );
    expect(port.imports, isEmpty);
  });

  test(
    'changing form or role during a picker cannot reinterpret its returned PNG',
    () async {
      final (controller, port) = await _open();
      final picker = Completer<String?>();
      var sameSelection = true;
      final operation = _workflow(() => controller).chooseMenuPng(
        formId: 'base',
        role: 'icon',
        picker: () => picker.future,
        isCurrentSelection: () => sameSelection,
      );
      sameSelection = false;
      picker.complete('/source/icon.png');
      expect(await operation, isFalse);
      expect(port.imports, isEmpty);
    },
  );

  test('replacing the workspace owner while picking cannot import into the new project', () async {
    final (controller, port) = await _open();
    final (newController, newPort) = await _open();
    var current = controller;
    final picker = Completer<String?>();
    final operation = _workflow(() => current).chooseMenuPng(
      formId: 'base',
      role: 'icon',
      picker: () => picker.future,
      isCurrentSelection: () => true,
    );
    current = newController;
    picker.complete('/source/icon.png');
    expect(await operation, isFalse);
    expect(port.imports, isEmpty);
    expect(newPort.imports, isEmpty);
  });

  test(
    'a draft edited during the picker is preserved and prevents publication',
    () async {
      final (controller, port) = await _open();
      final picker = Completer<String?>();
      final operation = _workflow(() => controller).chooseMenuPng(
        formId: 'base',
        role: 'icon',
        picker: () => picker.future,
        isCurrentSelection: () => true,
      );
      controller.edit(
        PokemonDocumentFamily.species,
        (json) => json['name'] = 'En cours',
      );
      picker.complete('/source/icon.png');
      expect(await operation, isFalse);
      expect(port.imports, isEmpty);
      expect(controller.hasPendingChanges, isTrue);
      expect(
        controller.selectedDraft!.document(
          PokemonDocumentFamily.species,
        )!['name'],
        'En cours',
      );
    },
  );

  test(
    'a second picker and a late result after closure cannot publish',
    () async {
      final (controller, port) = await _open();
      final workflow = _workflow(() => controller);
      final picker = Completer<String?>();
      final operation = workflow.chooseMenuPng(
        formId: 'base',
        role: 'icon',
        picker: () => picker.future,
        isCurrentSelection: () => true,
      );
      var duplicatePicks = 0;
      expect(
        await workflow.chooseMenuPng(
          formId: 'base',
          role: 'portrait',
          picker: () async {
            duplicatePicks++;
            return '/source/portrait.png';
          },
          isCurrentSelection: () => true,
        ),
        isFalse,
      );
      expect(duplicatePicks, 0);
      workflow.dispose();
      picker.complete('/source/icon.png');
      expect(await operation, isFalse);
      expect(port.imports, isEmpty);
      expect(workflow.choosingMedia, isFalse);
    },
  );
}

class _MediaPort implements PokemonWorkspacePort {
  final imports = <(String, String, String, String)>[];

  @override
  Future<String> importMenuPng({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  }) async {
    imports.add((speciesId, formId, role, sourcePath));
    return 'PNG importé';
  }

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: [
      PokemonSpeciesSummary(
        id: 'a',
        name: 'A',
        nationalDex: 1,
        generation: 1,
        types: [],
        formIds: ['base'],
        mediaRelativePath: 'media/a.json',
        enabled: true,
        relativePath: 'species/a.json',
      ),
    ],
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: [],
    items: {},
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      PokemonSpeciesBundle(
        species: PokemonDocumentSource(
          family: PokemonDocumentFamily.species,
          relativePath: entry.relativePath,
          bytes: null,
          document: {
            'id': 'a',
            'refs': {'media': 'media/a.json'},
          },
        ),
        learnset: null,
        evolution: null,
        media: PokemonDocumentSource(
          family: PokemonDocumentFamily.media,
          relativePath: 'media/a.json',
          bytes: null,
          document: {
            'speciesId': 'a',
            'variants': {'base': <String, dynamic>{}},
          },
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
