import 'dart:convert';

import 'package:avelune_studio/features/pokemon/domain/pokemon_external_import_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PokemonExternalImportPreview preview(String retainedReference) {
    final species = {
      'id': 'bulbasaur',
      'refs': {'learnset': 'custom-learn'},
    };
    final before = {
      'id': 'bulbasaur',
      'refs': {'learnset': retainedReference},
    };
    return PokemonExternalImportPreview(
      speciesId: 'bulbasaur',
      name: 'Bulbizarre',
      projectRevision: 'revision',
      inventorySignature: 'inventory',
      warnings: const [],
      documents: [
        PokemonExternalDocument(
          family: PokemonDocumentFamily.species,
          relativePath: 'species/bulbasaur.json',
          beforeBytes: utf8.encode(jsonEncode(before)),
          document: species,
        ),
        const PokemonExternalDocument(
          family: PokemonDocumentFamily.learnset,
          relativePath: 'learnsets/custom-learn.json',
          beforeBytes: null,
          document: {'speciesId': 'bulbasaur'},
        ),
      ],
    );
  }

  test('keeping a referenced species can create its missing companion', () {
    final plan = preview(
      'custom-learn',
    ).plan(PokemonExternalConflictPolicy.skipExisting);
    expect(plan.created, 1);
    expect(plan.kept, 1);
    expect(plan.excluded, isEmpty);
  });

  test('keeping an empty reference excludes its proposed companion', () {
    final plan = preview('').plan(PokemonExternalConflictPolicy.skipExisting);
    expect(plan.selected, isEmpty);
    expect(plan.kept, 1);
    expect(plan.excluded, ['learnsets/custom-learn.json']);
  });

  test('replacement writes the proposed species reference', () {
    final plan = preview(
      '',
    ).plan(PokemonExternalConflictPolicy.overwriteExisting);
    expect(plan.overwritten, 1);
    expect(plan.created, 1);
    expect(plan.excluded, isEmpty);
  });
}
