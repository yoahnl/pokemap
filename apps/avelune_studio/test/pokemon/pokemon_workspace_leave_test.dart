import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_workflow.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_import_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pokemon_authoring_fixture.dart';

Future<PokemonWorkspaceController> _owner(_Port port) async {
  final owner = PokemonWorkspaceController(port, changed: () {});
  addTearDown(owner.dispose);
  await owner.load();
  await owner.selectSpecies('a');
  return owner;
}

void _edit(PokemonWorkspaceController owner) => owner.edit(
  PokemonDocumentFamily.species,
  (json) => json['name'] = 'Brouillon',
);

void main() {
  for (final decision in PokemonDraftDecision.values) {
    test('leaving with $decision preserves or saves the real species owner', () async {
      final fixture = await PokemonAuthoringFixture.create(
        prepareSource: (source) async {
          final original = File(
            '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json',
          );
          final json =
              jsonDecode(await original.readAsString()) as Map<String, dynamic>;
          json['schemaVersion'] = 1;
          final file = File(
            '${source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
          );
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(json));
        },
      );
      addTearDown(fixture.dispose);
      await fixture.pokemon.selectSpecies('bulbasaur');
      final file = File(
        '${fixture.source.directory.path}/data/pokemon/species/0001-bulbasaur.json',
      );
      final before = await file.readAsBytes();
      fixture.pokemon.edit(PokemonDocumentFamily.species, (json) {
        (json['names'] as Map)['fr'] = 'Brouillon conservé';
      });
      fixture.decision = decision;
      final left = await fixture.workflow.requestLeave();
      expect(left, decision != PokemonDraftDecision.stay);
      expect(fixture.draftConfirmations, 1);
      expect(
        fixture.pokemon.hasPendingChanges,
        decision == PokemonDraftDecision.stay,
      );
      if (decision == PokemonDraftDecision.save) {
        final reopened = jsonDecode(await file.readAsString()) as Map;
        expect((reopened['names'] as Map)['fr'], 'Brouillon conservé');
      } else {
        expect(await file.readAsBytes(), before);
      }
    });
  }

  test(
    'leaving guards mutations while allowing read-only work without prompting',
    () async {
      final owner = await _owner(_Port());
      var confirmations = 0;
      final workflow = PokemonWorkspaceWorkflow(
        current: () => owner,
        isActive: () => true,
        confirmDraft: () async {
          confirmations++;
          return PokemonDraftDecision.save;
        },
      );
      addTearDown(workflow.dispose);
      owner.committing = true;
      expect(await workflow.requestLeave(), isFalse);
      owner.committing = false;
      owner.externalBusy = true;
      expect(await workflow.requestLeave(), isTrue);
      expect(confirmations, 0);
    },
  );

  test(
    'an owner replaced during confirmation is not saved or discarded',
    () async {
      final port = _Port();
      final owner = await _owner(port);
      final next = await _owner(_Port());
      _edit(owner);
      var current = owner;
      var confirmations = 0;
      final decision = Completer<PokemonDraftDecision?>();
      final workflow = PokemonWorkspaceWorkflow(
        current: () => current,
        isActive: () => true,
        confirmDraft: () {
          confirmations++;
          return decision.future;
        },
      );
      addTearDown(workflow.dispose);
      final pending = workflow.requestLeave();
      expect(await workflow.requestLeave(), isFalse);
      current = next;
      decision.complete(PokemonDraftDecision.save);
      expect(await pending, isFalse);
      expect(confirmations, 1);
      expect(port.writes, 0);
      expect(owner.hasPendingChanges, isTrue);
      expect(next.hasPendingChanges, isFalse);
    },
  );

  test(
    'a mutation started during confirmation keeps the pending draft',
    () async {
      final port = _Port();
      final owner = await _owner(port);
      _edit(owner);
      final decision = Completer<PokemonDraftDecision?>();
      final workflow = PokemonWorkspaceWorkflow(
        current: () => owner,
        isActive: () => true,
        confirmDraft: () => decision.future,
      );
      addTearDown(workflow.dispose);
      final pending = workflow.requestLeave();
      owner.committing = true;
      decision.complete(PokemonDraftDecision.save);
      expect(await pending, isFalse);
      expect(owner.hasPendingChanges, isTrue);
      expect(port.writes, 0);
    },
  );

  test('drafts and ongoing operations refuse the JSON picker', () async {
    final owner = await _owner(_Port());
    var selections = 0;
    final workflow = PokemonWorkspaceWorkflow(
      current: () => owner,
      isActive: () => true,
      confirmDraft: () async => PokemonDraftDecision.stay,
    );
    addTearDown(workflow.dispose);
    Future<String?> pick() async {
      selections++;
      return null;
    }

    _edit(owner);
    expect(await workflow.pickJson(pick), isFalse);
    expect(workflow.refusal, contains('Enregistrez ou annulez'));
    owner.discardActiveOwner();
    owner.externalBusy = true;
    expect(await workflow.pickJson(pick), isFalse);
    expect(selections, 0);
  });

  test(
    'a late JSON selection cannot prepare import in a replaced owner',
    () async {
      final port = _Port();
      final owner = await _owner(port);
      final next = await _owner(_Port());
      var current = owner;
      final selection = Completer<String?>();
      final workflow = PokemonWorkspaceWorkflow(
        current: () => current,
        isActive: () => true,
        confirmDraft: () async => PokemonDraftDecision.stay,
      );
      addTearDown(workflow.dispose);
      final pending = workflow.pickJson(() => selection.future);
      current = next;
      selection.complete('/fixture/species.json');
      expect(await pending, isFalse);
      expect(port.previews, 0);
      expect(owner.importPreview, isNull);
      expect(next.importPreview, isNull);
    },
  );

  test('a completed save cannot leave through a replaced owner', () async {
    final gate = Completer<void>();
    final port = _Port()..saveGate = gate;
    final owner = await _owner(port);
    final next = await _owner(_Port());
    _edit(owner);
    var current = owner;
    final workflow = PokemonWorkspaceWorkflow(
      current: () => current,
      isActive: () => true,
      confirmDraft: () async => PokemonDraftDecision.save,
    );
    addTearDown(workflow.dispose);
    final pending = workflow.requestLeave();
    await port.saveStarted.future;
    current = next;
    gate.complete();
    expect(await pending, isFalse);
    expect(port.writes, 1);
    expect(next.hasPendingChanges, isFalse);
  });
  for (final conflicts in [false, true]) {
    test(
      'JSON import applies the captured preview with explicit conflict consent $conflicts',
      () async {
        final port = _Port();
        final owner = await _owner(port);
        owner.importPreview = _preview(conflicts: conflicts);
        var confirmations = 0;
        final workflow = PokemonWorkspaceWorkflow(
          current: () => owner,
          isActive: () => true,
          confirmDraft: () async => PokemonDraftDecision.stay,
        );
        addTearDown(workflow.dispose);
        expect(
          await workflow.applyJsonImport(() async {
            confirmations++;
            return true;
          }),
          isTrue,
        );
        expect(confirmations, conflicts ? 1 : 0);
        expect(port.applies, 1);
        expect(port.overwrite, conflicts);
        expect(owner.importPreview, isNull);
        expect(owner.selectedId, 'a');
      },
    );
  }

  test('refused JSON overwrite keeps the preview without writing', () async {
    final port = _Port();
    final owner = await _owner(port);
    final preview = _preview(conflicts: true);
    owner.importPreview = preview;
    final workflow = PokemonWorkspaceWorkflow(
      current: () => owner,
      isActive: () => true,
      confirmDraft: () async => PokemonDraftDecision.stay,
    );
    addTearDown(workflow.dispose);
    expect(await workflow.applyJsonImport(() async => false), isFalse);
    expect(port.applies, 0);
    expect(owner.importPreview, same(preview));
  });

  test('late JSON overwrite consent cannot apply a newer preview', () async {
    final port = _Port();
    final owner = await _owner(port);
    owner.importPreview = _preview(conflicts: true);
    final consent = Completer<bool>();
    final workflow = PokemonWorkspaceWorkflow(
      current: () => owner,
      isActive: () => true,
      confirmDraft: () async => PokemonDraftDecision.stay,
    );
    addTearDown(workflow.dispose);
    final importing = workflow.applyJsonImport(() => consent.future);
    final next = _preview(conflicts: true);
    owner.importPreview = next;
    consent.complete(true);
    expect(await importing, isFalse);
    expect(port.applies, 0);
    expect(owner.importPreview, same(next));
  });

  test(
    'late external overwrite consent cannot apply a changed preview',
    () async {
      final port = _Port();
      final owner = await _owner(port);
      owner.externalPreview = _externalPreview();
      final consent = Completer<bool>();
      final workflow = PokemonWorkspaceWorkflow(
        current: () => owner,
        isActive: () => true,
        confirmDraft: () async => PokemonDraftDecision.stay,
      );
      addTearDown(workflow.dispose);
      final importing = workflow.applyExternal(
        PokemonExternalConflictPolicy.overwriteExisting,
        () => consent.future,
      );
      final next = _externalPreview();
      expect(identical(owner.externalPreview, next), isFalse);
      owner.externalPreview = next;
      consent.complete(true);
      expect(await importing, isFalse);
      expect(port.externalApplies, 0);
      expect(owner.externalPreview, same(next));
    },
  );

  test(
    'refused external overwrite keeps all prepared documents without writing',
    () async {
      final port = _Port();
      final owner = await _owner(port);
      final preview = _externalPreview();
      owner.externalPreview = preview;
      final workflow = PokemonWorkspaceWorkflow(
        current: () => owner,
        isActive: () => true,
        confirmDraft: () async => PokemonDraftDecision.stay,
      );
      addTearDown(workflow.dispose);
      expect(
        await workflow.applyExternal(
          PokemonExternalConflictPolicy.overwriteExisting,
          () async => false,
        ),
        isFalse,
      );
      expect(port.externalApplies, 0);
      expect(owner.externalPreview, same(preview));
    },
  );

  test('refused species selection preserves the current draft and selected identity', () async {
    final port = _Port();
    final owner = await _owner(port);
    _edit(owner);
    final workflow = PokemonWorkspaceWorkflow(
      current: () => owner,
      isActive: () => true,
      confirmDraft: () async => PokemonDraftDecision.stay,
    );
    addTearDown(workflow.dispose);
    expect(await workflow.requestSpecies('b'), isFalse);
    expect(owner.selectedId, 'a');
    expect(owner.hasPendingChanges, isTrue);
    expect(port.writes, 0);
  });
}

class _Port implements PokemonWorkspacePort {
  Map<String, dynamic> value = {'id': 'a', 'name': 'Initial'};
  Completer<void>? saveGate;
  final saveStarted = Completer<void>();
  int writes = 0, previews = 0, applies = 0, externalApplies = 0;
  bool? overwrite;

  PokemonSpeciesBundle get bundle => PokemonSpeciesBundle(
    species: PokemonDocumentSource(
      family: PokemonDocumentFamily.species,
      relativePath: 'a.json',
      bytes: null,
      document: Map.from(value),
    ),
    learnset: null,
    evolution: null,
    media: null,
  );

  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: [
      PokemonSpeciesSummary(
        id: 'a',
        name: 'Initial',
        nationalDex: 1,
        generation: 1,
        types: [],
        formIds: [],
        mediaRelativePath: '',
        enabled: true,
        relativePath: 'a.json',
      ),
    ],
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: [],
    items: {},
  );

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      bundle;

  @override
  Future<PokemonLocalImportPreview> previewJsonImport(String path) async {
    previews++;
    throw StateError('Unexpected JSON preparation');
  }

  @override
  Future<String> applyJsonImport(
    PokemonLocalImportPreview preview, {
    required bool confirmOverwrite,
  }) async {
    applies++;
    overwrite = confirmOverwrite;
    return 'a';
  }

  @override
  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  ) async {
    externalApplies++;
    throw StateError('Unexpected external publication');
  }

  @override
  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft) async {
    if (!saveStarted.isCompleted) saveStarted.complete();
    await saveGate?.future;
    writes++;
    value = Map.from(draft.document(PokemonDocumentFamily.species)!);
    return bundle;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PokemonLocalImportPreview _preview({required bool conflicts}) =>
    PokemonLocalImportPreview(
      speciesId: 'a',
      name: 'Initial',
      fingerprint: 'fingerprint',
      items: [
        PokemonLocalImportItem(
          family: PokemonDocumentFamily.species,
          sourcePath: '/source/a.json',
          relativePath: 'a.json',
          sourceBytes: const [1],
          beforeBytes: conflicts ? const [1] : null,
          document: const {'id': 'a'},
        ),
      ],
    );

PokemonExternalImportPreview _externalPreview() =>
    PokemonExternalImportPreview(
      speciesId: 'a',
      name: 'Initial',
      projectRevision: 'r',
      inventorySignature: 'i',
      warnings: [],
      documents: [
        PokemonExternalDocument(
          family: PokemonDocumentFamily.species,
          relativePath: 'a.json',
          beforeBytes: [1],
          document: {'id': 'a'},
        ),
      ],
    );
