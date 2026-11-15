import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

import '../support/dialogue_adapter_fixture.dart';

Future<int> _publishWithUnrelated(int unrelated) async {
  final draft = readLocalizedDialogue(
    source: DialogueAdapterFixture.source,
    sourceLocale: 'fr',
  );
  final entry = DialogueAdapterFixture.entry.copyWith(
    localization: draft.localization,
  );
  final f = await DialogueAdapterFixture.create(
    entries: [
      entry,
      for (var i = 0; i < unrelated; i++)
        DialogueAdapterFixture.entry.copyWith(
          id: 'unrelated_$i',
          relativePath: 'dialogues/unrelated_$i.yarn',
        ),
    ],
  );
  addTearDown(f.dispose);
  final reader = DialogueCountingReader();
  final port = f.adapter(reader: reader);
  final base = await port.load(entry.id);
  expect(reader.paths, [entry.relativePath]);
  final reads = reader.paths.length;
  final catalog = base.entry.localization!.translate(
    base.entry.localization!.units.single.id,
    'en',
    'Hello',
  );
  reader.paths.clear();
  final saved = await port.publish(
    id: entry.id,
    base: base,
    entry: base.entry.copyWith(localization: catalog),
    source: base.source,
  );
  expect(saved.resources.changedPaths, ['project.json']);
  expect(reader.paths.every((path) => path == entry.relativePath), isTrue);
  final reopened = await f.adapter().load(entry.id);
  expect(reopened.entry.localization, catalog);
  expect(reopened.source, DialogueAdapterFixture.source);
  final bytes = await f.file('project.json').readAsBytes();
  await expectLater(
    port.publish(
      id: entry.id,
      base: reopened,
      entry: reopened.entry,
      source: reopened.source.replaceFirst('Bonjour', 'Salut'),
    ),
    throwsA(isA<DialogueFailure>()),
  );
  expect(await f.file('project.json').readAsBytes(), bytes);
  expect(
    await f.file(entry.relativePath).readAsString(),
    DialogueAdapterFixture.source,
  );
  return reads;
}

void main() {
  test('Studio loads one localized source and persists variants through the canonical adapter', () async {
    final small = await _publishWithUnrelated(5);
    final large = await _publishWithUnrelated(50);
    expect(small, greaterThan(0));
    expect(large, small);
  });
}
