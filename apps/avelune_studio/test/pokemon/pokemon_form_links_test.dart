import 'dart:typed_data';

import 'package:avelune_studio/features/pokemon/application/pokemon_document_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

Future<PokemonWorkspaceController> _open() async {
  final controller = PokemonWorkspaceController(_FormsPort(), changed: () {});
  addTearDown(controller.dispose);
  await controller.load();
  expect(await controller.selectSpecies('raichu'), isTrue);
  return controller;
}

Map<String, dynamic> _forms(PokemonWorkspaceController controller) =>
    (controller.selectedDraft!.document(PokemonDocumentFamily.species)!['forms']
            as Map)
        .cast<String, dynamic>();
List<String> _links(PokemonWorkspaceController controller) =>
    List<String>.from(_forms(controller)['otherForms'] as List);
void _write(PokemonWorkspaceController controller, List<String> forms) =>
    controller.edit(
      PokemonDocumentFamily.species,
      (json) => PokemonDocumentEditing.setForms(json, forms),
    );
List<PokemonSpeciesSummary> _candidates(
  PokemonWorkspaceController controller,
  String query,
) => PokemonDocumentEditing.formCandidates(
  entries: controller.index!.entries,
  forms: _forms(controller),
  ownerId: controller.selectedId,
  query: query,
);

void main() {
  test(
    'linked form names resolve without dropping unresolved references',
    () async {
      final controller = await _open();
      final links = PokemonDocumentEditing.formLinks(
        entries: controller.index!.entries,
        forms: _forms(controller),
        ownerId: controller.selectedId,
      );
      expect(links.map((link) => link.formId), ['alola', 'gmax-inconnue']);
      expect(links.first.resolved!.name, 'Raichu d’Alola');
      expect(links.first.matches.single.id, 'raichu-alola');
      expect(links.last.matches, isEmpty);
      expect(links.last.resolved, isNull);
      expect(_links(controller), ['alola', 'gmax-inconnue']);
    },
  );

  test('form link projection preserves ambiguity order and raw duplicates without modifying its source', () {
    final sourceLinks = ['alola', 'unknown', 'mega', 'alola'];
    final forms = <String, dynamic>{
      'formId': 'base',
      'isBaseForm': true,
      'baseFormId': 'raichu',
      'otherForms': sourceLinks,
      'formName': 'Original',
    };
    final links = PokemonDocumentEditing.formLinks(
      entries: [
        _summary('raichu', 'Raichu', formId: 'base'),
        _summary(
          'raichu-alola-a',
          'Homonyme',
          formId: 'alola',
          baseFormId: 'raichu',
        ),
        _summary(
          'raichu-alola-b',
          'Homonyme',
          formId: 'alola',
          baseFormId: 'raichu',
        ),
        _summary(
          'pikachu-alola',
          'Homonyme',
          formId: 'alola',
          baseFormId: 'pikachu',
        ),
        _summary(
          'raichu-mega',
          'Méga-Raichu',
          formId: 'mega',
          baseFormId: 'raichu',
        ),
      ],
      forms: forms,
      ownerId: 'raichu',
    );
    expect(links.map((link) => link.formId), sourceLinks);
    expect(links.first.matches.map((entry) => entry.id), [
      'raichu-alola-a',
      'raichu-alola-b',
    ]);
    expect(links.first.resolved, isNull);
    expect(links[1].matches, isEmpty);
    expect(links[1].resolved, isNull);
    expect(links[2].resolved!.id, 'raichu-mega');
    expect(links.last.matches.map((entry) => entry.id), [
      'raichu-alola-a',
      'raichu-alola-b',
    ]);
    expect(links.last.resolved, isNull);
    expect(forms['otherForms'], same(sourceLinks));
    expect(sourceLinks, ['alola', 'unknown', 'mega', 'alola']);
    expect(forms['formName'], 'Original');
    expect(() => links.clear(), throwsUnsupportedError);
    expect(() => links.first.matches.clear(), throwsUnsupportedError);
  });

  test(
    'form links remain unresolved when their owning group is unavailable',
    () {
      final links = PokemonDocumentEditing.formLinks(
        entries: [
          _summary(
            'raichu-alola',
            'Raichu d’Alola',
            formId: 'alola',
            baseFormId: 'raichu',
          ),
        ],
        forms: {
          'otherForms': ['alola'],
        },
        ownerId: null,
      );
      expect(links.single.formId, 'alola');
      expect(links.single.matches, isEmpty);
      expect(links.single.resolved, isNull);
      expect(
        PokemonDocumentEditing.formLinks(
          entries: const [],
          forms: const {},
          ownerId: null,
        ),
        isEmpty,
      );
    },
  );

  test(
    'search offers only unlinked forms from the same base species',
    () async {
      final controller = await _open();
      expect(_candidates(controller, '').map((entry) => entry.id), [
        'raichu-mega',
      ]);
      expect(_candidates(controller, 'pika'), isEmpty);
      final candidate = _candidates(controller, 'MÉGA').single;
      _write(
        controller,
        PokemonDocumentEditing.addForm(_forms(controller), candidate.formId),
      );
      expect(_links(controller), ['alola', 'gmax-inconnue', 'mega']);
      expect(_candidates(controller, ''), isEmpty);
    },
  );

  test(
    'removing a form link keeps all other references and supports undo',
    () async {
      final controller = await _open();
      _write(
        controller,
        PokemonDocumentEditing.removeForm(_forms(controller), 0),
      );
      expect(_links(controller), ['gmax-inconnue']);
      expect(
        _candidates(controller, '').map((entry) => entry.id),
        contains('raichu-alola'),
      );
      controller.undo();
      expect(_links(controller), ['alola', 'gmax-inconnue']);
    },
  );

  test('advanced raw identifiers remain intact and ignore empty comma-separated values', () async {
    final controller = await _open();
    _write(
      controller,
      PokemonDocumentEditing.parseFormLinks(' alola, , unresolved , alola '),
    );
    expect(_links(controller), ['alola', 'unresolved', 'alola']);
    expect(_forms(controller)['baseFormId'], 'raichu');
    expect(_forms(controller)['isBaseForm'], isTrue);
  });

  test('repeated raw edits retain the latest value and preserve the previous snapshot', () async {
    final controller = await _open();
    _write(controller, PokemonDocumentEditing.parseFormLinks('alola'));
    final before = controller.selectedDraft!.document(
      PokemonDocumentFamily.species,
    )!;
    _write(controller, PokemonDocumentEditing.parseFormLinks('alola, mega'));
    expect(_links(controller), ['alola', 'mega']);
    expect((before['forms'] as Map)['otherForms'], ['alola']);
    controller.undo();
    expect(_links(controller), ['alola']);
  });

  test('form drafts survive moving between detail sections and discard restores the source', () async {
    final controller = await _open();
    _write(controller, PokemonDocumentEditing.parseFormLinks('alola, mega'));
    controller.setSection(PokemonDetailSection.overview);
    controller.setSection(PokemonDetailSection.forms);
    expect(_links(controller), ['alola', 'mega']);
    expect(controller.selectedDraft!.dirty, isTrue);
    controller.discardSelectedSpecies();
    expect(_links(controller), ['alola', 'gmax-inconnue']);
  });
}

final class _FormsPort implements PokemonWorkspacePort {
  @override
  Future<PokemonWorkspaceIndex> loadIndex() async => PokemonWorkspaceIndex(
    enabled: true,
    entries: [
      _summary('pikachu', 'Pikachu', formId: 'base'),
      _summary(
        'raichu',
        'Raichu',
        formId: 'base',
        otherForms: ['alola', 'gmax-inconnue'],
      ),
      _summary(
        'raichu-alola',
        'Raichu d’Alola',
        formId: 'alola',
        baseFormId: 'raichu',
        otherForms: ['base'],
      ),
      _summary(
        'raichu-mega',
        'Méga-Raichu',
        formId: 'mega',
        baseFormId: 'raichu',
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
            'id': entry.id,
            'forms': {
              'baseFormId': entry.id,
              'formId': entry.formId,
              'isBaseForm': true,
              'otherForms': ['alola', 'gmax-inconnue'],
            },
          },
        ),
        learnset: null,
        evolution: null,
        media: null,
      );

  @override
  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PokemonSpeciesSummary _summary(
  String id,
  String name, {
  required String formId,
  String? baseFormId,
  List<String> otherForms = const [],
}) => PokemonSpeciesSummary(
  id: id,
  name: name,
  nationalDex: 26,
  generation: 1,
  types: const [],
  formIds: [formId, ...otherForms],
  formId: formId,
  baseFormId: baseFormId ?? id,
  isBaseForm: baseFormId == null,
  mediaRelativePath: '',
  enabled: true,
  relativePath: '$id.json',
);
