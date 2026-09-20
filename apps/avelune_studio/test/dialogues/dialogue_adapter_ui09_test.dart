import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_adapter_fixture.dart';

void main() {
  test(
    '100 entries load only the requested source by ID without any map',
    () async {
      final f = await DialogueAdapterFixture.create(
        entries: [
          for (var i = 0; i < 100; i++)
            DialogueAdapterFixture.entry.copyWith(
              id: 'dialogue_$i',
              relativePath: 'dialogues/$i.yarn',
            ),
        ],
      );
      addTearDown(f.dispose);
      final reader = DialogueCountingReader();
      final port = f.adapter(reader: reader);
      expect(reader.paths, isEmpty);
      final loaded = await port.load('dialogue_64');
      expect(loaded.entry.id, 'dialogue_64');
      expect(reader.paths, ['dialogues/64.yarn']);
      expect((await f.readManifest()).maps, isEmpty);
    },
  );

  test(
    'create rename duplicate and delete are targeted and map independent',
    () async {
      final f = await DialogueAdapterFixture.create(entries: []);
      addTearDown(f.dispose);
      final port = f.adapter();
      final created = await port.publish(
        id: 'gare',
        base: null,
        entry: DialogueAdapterFixture.entry,
        source: DialogueAdapterFixture.source,
      );
      expect(created.resources.changedPaths.toSet(), {
        'project.json',
        'dialogues/gare.yarn',
      });
      final renamed = await port.publish(
        id: 'gare',
        base: created.snapshot,
        entry: created.snapshot!.entry.copyWith(name: 'Renommé'),
        source: created.snapshot!.source,
      );
      expect(renamed.snapshot!.entry.id, 'gare');
      expect(renamed.snapshot!.entry.relativePath, 'dialogues/gare.yarn');
      final copy = renamed.snapshot!.entry.copyWith(
        id: 'gare_copie',
        relativePath: 'dialogues/gare_copie.yarn',
      );
      final duplicate = await port.publish(
        id: copy.id,
        base: null,
        entry: copy,
        source: renamed.snapshot!.source,
      );
      expect(duplicate.snapshot!.source, DialogueAdapterFixture.source);
      final deleted = await port.publish(
        id: 'gare',
        base: renamed.snapshot,
        entry: null,
        source: null,
      );
      expect(deleted.snapshot, isNull);
      expect(await f.file('dialogues/gare.yarn').exists(), isFalse);
      expect((await f.readManifest()).dialogues, [copy]);
      expect((await f.readManifest()).maps, isEmpty);
    },
  );

  test(
    'atomic metadata and source publish declares and emits the same outcome',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final base = await port.load('gare');
      final entry = base.entry.copyWith(
        declaredOutcomes: const [
          DialogueDeclaredOutcome(id: 'partir', label: 'Partir'),
        ],
      );
      const source =
          'title: Accueil\n---\nBonjour !\n-> Partir\n  <<outcome partir>>\n===\n';
      final saved = await port.publish(
        id: 'gare',
        base: base,
        entry: entry,
        source: source,
      );
      final disk = (await f.readManifest()).dialogues.single;
      final actual = await f.file(disk.relativePath).readAsString();
      final compiled = const DialogueAuthoringCompiler().compile(
        entry: disk,
        source: actual,
      );
      expect(compiled.canPublish, isTrue);
      expect(compiled.emittedOutcomes, ['partir']);
      expect(saved.snapshot!.revision, isNot(base.revision));
      expect(saved.resources.changedPaths.toSet(), {
        'project.json',
        'dialogues/gare.yarn',
      });
    },
  );

  test(
    'source-only receipt changes source revision while preserving manifest bytes',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final before = await f.file('project.json').readAsBytes();
      final base = await port.load('gare');
      final saved = await port.publish(
        id: 'gare',
        base: base,
        entry: base.entry,
        source: base.source.replaceFirst('Bonjour', 'Bonsoir'),
      );
      expect(await f.file('project.json').readAsBytes(), before);
      expect(saved.resources.changedPaths, ['dialogues/gare.yarn']);
      expect(saved.resources.revision, saved.resources.beforeRevision);
      expect(saved.snapshot!.revision, isNot(base.revision));
      expect((await port.load('gare')).source, contains('Bonsoir'));
    },
  );

  test(
    'source and metadata conflicts refuse writes and preserve external edits',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final base = await port.load('gare');
      final file = f.file(base.entry.relativePath);
      await file.writeAsString(base.source.replaceFirst('Bonjour', 'Externe'));
      await expectLater(
        port.publish(
          id: 'gare',
          base: base,
          entry: base.entry,
          source: base.source.replaceFirst('Bonjour', 'Locale'),
        ),
        throwsA(isA<DialogueFailure>()),
      );
      expect(await file.readAsString(), contains('Externe'));
      final reloaded = await port.load('gare');
      final manifest = await f.readManifest();
      await f.writeManifest(
        manifest.copyWith(
          dialogues: [base.entry.copyWith(name: 'Nom externe')],
        ),
      );
      await expectLater(
        port.publish(
          id: 'gare',
          base: reloaded,
          entry: base.entry,
          source: base.source,
        ),
        throwsA(isA<DialogueFailure>()),
      );
      expect((await f.readManifest()).dialogues.single.name, 'Nom externe');
      expect(await file.readAsString(), contains('Externe'));
    },
  );

  test(
    'unrelated external catalog changes survive publication on fresh baseline',
    () async {
      final f = await DialogueAdapterFixture.create();
      addTearDown(f.dispose);
      final port = f.adapter();
      final base = await port.load('gare');
      final other = base.entry.copyWith(
        id: 'other',
        relativePath: 'dialogues/other.yarn',
      );
      await f.file(other.relativePath).writeAsString(base.source);
      await f.writeManifest(
        (await f.readManifest()).copyWith(
          name: 'Nouveau nom',
          dialogues: [base.entry, other],
        ),
      );
      final saved = await port.publish(
        id: 'gare',
        base: base,
        entry: base.entry.copyWith(name: 'Publication ciblée'),
        source: base.source,
      );
      final after = await f.readManifest();
      expect(after.name, 'Nouveau nom');
      expect(after.dialogues, [saved.snapshot!.entry, other]);
      expect(await f.file(other.relativePath).readAsString(), base.source);
    },
  );
}
