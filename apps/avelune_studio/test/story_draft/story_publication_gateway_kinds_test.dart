import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_manifest_reader.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_plan.dart';
import 'package:avelune_studio/features/story_draft/application/story_saved_dialogues.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_saved.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_draft_fixtures.dart';
import 'story_fake_ports.dart';

void main() {
  late ProjectManifest project;
  late StoryFakePorts ports;
  late StoryDraft draft;
  late StorySavedDialogues dialogues;
  final reader = StoryDraftManifestReader();

  setUp(() {
    project = manifest(events: [event(1)]);
    ports = StoryFakePorts(() => project);
    draft = StoryDraft();
    dialogues = StorySavedDialogues();
  });

  StoryDraftSaved saved() => reader.of(project, beyond: dialogues);

  void write<T extends Object>(StoryDraftKind<T> kind, String id, T? value) {
    draft.load(kind, id, saved().read(kind, id) as T?);
    value == null ? draft.remove(kind, id) : draft.put(kind, value);
  }

  Future<Object?> publish() =>
      StoryPublicationGateway(
            draft: draft,
            events: ports,
            scenes: ports,
            dialogues: ports,
            facts: ports,
            savedDialogues: dialogues,
          )
          .publish(
            planStoryPublication(draft.changes(saved())),
            land: (write) async {
              project = (await write()).manifest;
              return saved();
            },
          )
          .then<Object?>(
            (progress) => progress,
            onError: (Object error) => error,
          );

  void newLine() => draft.group(() {
    write(StoryDraftKind.event, eventId(1), event(1, 'Parler'));
    write(StoryDraftKind.scene, 'scene_line', scene('scene_line'));
    write(StoryDraftKind.dialogue, 'line', dialogue('line', 'Salut'));
  });

  test('a new line writes its dialogue, its scene, then its event', () async {
    newLine();

    expect(await publish(), isA<StoryPublicationProgress>());

    expect(ports.calls, [
      'dialogue line',
      'scene scene_line',
      'event ${eventId(1)}',
    ]);
    expect(draft.dirty(saved()), isFalse);
    expect(dialogues['line']?.source, 'Salut');
    expect(dialogues['line']?.revision, 'dialogue-1');
    expect(project.scenes.single.id, 'scene_line');
    expect(project.eventRegistry!.records.single.name, 'Parler');
  });

  test('a failed scene write keeps the scene and the event dirty', () async {
    newLine();
    ports.refuse = (call) =>
        call.startsWith('scene') ? const SceneFailure('disk full') : null;

    final failure = await publish();

    expect(failure, isA<StoryPublicationFailed>());
    failure as StoryPublicationFailed;
    expect('$failure', 'disk full');
    expect([for (final entry in failure.progress.saved) entry.id], ['line']);
    expect(
      [for (final entry in failure.progress.remaining) entry.id],
      ['scene_line', eventId(1)],
    );
    expect(ports.calls, ['dialogue line', 'scene scene_line']);
    expect(
      [for (final change in draft.changes(saved())) change.id],
      [eventId(1), 'scene_line'],
    );

    ports.refuse = null;
    expect(await publish(), isA<StoryPublicationProgress>());
    expect(ports.calls.skip(2), ['scene scene_line', 'event ${eventId(1)}']);
    expect(draft.dirty(saved()), isFalse);
  });

  test('a dialogue changed on disk is refused and the edit is kept', () async {
    final talk = dialogue('talk', 'Bonjour');
    project = manifest(events: [event(1)], dialogues: [talk]);
    ports.sources['talk'] = DialogueSourceSnapshot(
      entry: talk.entry,
      source: talk.source,
      revision: 'disk-1',
    );
    dialogues.remember(
      StoryDialogueSource(
        entry: talk.entry,
        source: talk.source,
        revision: 'disk-1',
      ),
    );
    write(StoryDraftKind.dialogue, 'talk', dialogue('talk', 'Salut'));
    ports.sources['talk'] = DialogueSourceSnapshot(
      entry: talk.entry,
      source: 'Coucou',
      revision: 'disk-2',
    );

    final failure = await publish();

    expect(failure, isA<StoryPublicationFailed>());
    expect((failure as StoryPublicationFailed).cause, isA<DialogueFailure>());
    expect(ports.calls, ['dialogue talk']);
    expect(
      draft.changesOf(StoryDraftKind.dialogue, saved()).single.current?.source,
      'Salut',
    );

    ports.sources['talk'] = DialogueSourceSnapshot(
      entry: talk.entry,
      source: talk.source,
      revision: 'disk-1',
    );
    expect(await publish(), isA<StoryPublicationProgress>());
    expect(ports.sources['talk']?.source, 'Salut');
    expect(dialogues['talk']?.revision, ports.sources['talk']?.revision);
    expect(draft.dirty(saved()), isFalse);
  });

  test('a new fact is written before the event that tests it', () async {
    draft.group(() {
      write(StoryDraftKind.fact, 'fact_met', fact('fact_met', 'Rencontré'));
      write(StoryDraftKind.event, eventId(1), event(1, 'Si rencontré'));
    });

    expect(await publish(), isA<StoryPublicationProgress>());

    expect(ports.calls, ['fact fact_met', 'event ${eventId(1)}']);
    expect(project.facts.single.label, 'Rencontré');
    expect(draft.dirty(saved()), isFalse);
  });

  test('a new world rule is written after the fact it tests', () async {
    draft.group(() {
      write(StoryDraftKind.worldRule, 'gate', rule('gate', 'Porte'));
      write(StoryDraftKind.fact, 'fact', fact('fact', 'Clé trouvée'));
    });

    expect(await publish(), isA<StoryPublicationProgress>());

    expect(ports.calls, ['fact fact', 'rule gate']);
    expect(project.worldRules.single.label, 'Porte');
    expect(draft.dirty(saved()), isFalse);
  });

  test('a world rule changed on disk stays in the draft', () async {
    project = manifest(events: [event(1)], rules: [rule('gate', 'Disque')]);
    write(StoryDraftKind.worldRule, 'gate', rule('gate', 'Mienne'));
    project = manifest(events: [event(1)], rules: [rule('gate', 'Ailleurs')]);

    expect(await publish(), isA<StoryPublicationProgress>());

    expect(ports.calls, isEmpty);
    expect(draft.conflicts(saved()), [
      (kind: StoryDraftKind.worldRule, id: 'gate'),
    ]);
  });

  test('a scene deletion is refused before anything is written', () async {
    project = manifest(events: [event(1)], scenes: [scene('old')]);
    draft.group(() {
      write(StoryDraftKind.event, eventId(1), event(1, 'Renommé'));
      write<SceneAsset>(StoryDraftKind.scene, 'old', null);
    });

    final failure = await publish();

    expect(failure, isA<StoryPublicationUnsupported>());
    expect((failure as StoryPublicationUnsupported).kinds, {
      StoryDraftKind.scene,
    });
    expect(ports.calls, isEmpty);
    expect(draft.changes(saved()), hasLength(2));
  });
}
