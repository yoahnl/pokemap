import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_manifest_reader.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_plan.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_saved.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_draft_fixtures.dart';

class _Port implements EventPort {
  _Port(this.project);

  ProjectManifest project;
  final calls = <String>[];
  Object? Function(int call, List<EventRecordChange> changes)? refuse;

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async => _write('one', [(id: id, base: base, current: current)]);

  Future<ResourceMutationReceipt> _write(
    String port,
    List<EventRecordChange> changes,
  ) async {
    calls.add(
      '$port ${[for (final change in changes) '${change.id}=${change.current?.name}'].join(' ')}',
    );
    if (refuse?.call(calls.length, changes) case final failure?) {
      throw failure;
    }
    final before = project;
    final written = {for (final change in changes) change.id: change.current};
    final records = before.eventRegistry!.records;
    final known = {for (final record in records) record.id};
    project = before.copyWith(
      eventRegistry: registry([
        for (final record in records)
          if (!written.containsKey(record.id)) record else ?written[record.id],
        for (final change in changes)
          if (!known.contains(change.id)) ?change.current,
      ]),
    );
    return ResourceMutationReceipt(
      before: before,
      manifest: project,
      beforeRevision: 'r${calls.length - 1}',
      revision: 'r${calls.length}',
      changedPaths: const ['project.json'],
    );
  }
}

class _BatchPort extends _Port implements EventBatchPort {
  _BatchPort(super.project);

  @override
  Future<ResourceMutationReceipt> publishEvents(
    List<EventRecordChange> changes,
  ) => _write('batch', changes);
}

String _call(String port, Map<String, String?> names) =>
    '$port ${[for (final MapEntry(:key, :value) in names.entries) '$key=$value'].join(' ')}';

void main() {
  late StoryDraft draft;
  late StoryDraftManifestReader reader;
  late int landings;

  setUp(() {
    draft = StoryDraft();
    reader = StoryDraftManifestReader();
    landings = 0;
  });

  StoryDraftSaved savedOf(_Port port) => reader.of(port.project);

  void rename(_Port port, int index, String name) {
    draft.load(
      StoryDraftKind.event,
      eventId(index),
      savedOf(port).read(StoryDraftKind.event, eventId(index))
          as NarrativeEventRecord?,
    );
    draft.put(StoryDraftKind.event, event(index, name));
  }

  void delete(_Port port, int index) {
    draft.load(
      StoryDraftKind.event,
      eventId(index),
      savedOf(port).read(StoryDraftKind.event, eventId(index))
          as NarrativeEventRecord?,
    );
    draft.remove(StoryDraftKind.event, eventId(index));
  }

  Future<StoryPublicationProgress> publish(_Port port) =>
      StoryPublicationGateway(draft: draft, events: port).publish(
        planStoryPublication(draft.changes(savedOf(port))),
        land: (write) async {
          landings++;
          return reader.of((await write()).manifest);
        },
      );

  List<String> dirtyIds(_Port port) => [
    for (final change in draft.changes(savedOf(port))) change.id,
  ];

  _BatchPort batchPort(int count) => _BatchPort(
    manifest(
      events: [for (var index = 1; index <= count; index++) event(index)],
    ),
  );

  test('event writes go by batches of 128, deletions one by one', () async {
    final port = batchPort(133);
    delete(port, 1);
    for (var index = 2; index <= 132; index++) {
      rename(port, index, 'renamed $index');
    }
    delete(port, 133);

    final progress = await publish(port);

    String renamed(int from, int to) => _call('batch', {
      for (var index = from; index <= to; index++)
        eventId(index): 'renamed $index',
    });
    expect(port.calls, [
      renamed(2, 129),
      renamed(130, 132),
      _call('one', {eventId(1): null}),
      _call('one', {eventId(133): null}),
    ]);
    expect(progress.complete, isTrue);
    expect(progress.saved, hasLength(133));
    expect(progress.remaining, isEmpty);
    expect(draft.dirty(savedOf(port)), isFalse);
    expect(port.project.eventRegistry!.records, hasLength(131));
  });

  test('a single-record port gets one call per written event', () async {
    final port = _Port(batchPort(3).project);
    rename(port, 1, 'one');
    delete(port, 2);
    rename(port, 3, 'three');

    final progress = await publish(port);

    expect(port.calls, [
      _call('one', {eventId(1): 'one'}),
      _call('one', {eventId(3): 'three'}),
      _call('one', {eventId(2): null}),
    ]);
    expect(progress.complete, isTrue);
    expect(draft.dirty(savedOf(port)), isFalse);
  });

  test('a refused deletion surfaces as is and stays in the draft', () async {
    final port = batchPort(3);
    rename(port, 1, 'kept');
    delete(port, 2);
    delete(port, 3);
    final refusal = EventDeletionRefused.inUse(const [
      (kind: 'scene', label: 'Scène'),
    ]);
    port.refuse = (call, changes) =>
        changes.single.id == eventId(2) ? refusal : null;

    final failure = await publish(port)
        .then<Object?>((_) => null, onError: (Object error) => error);

    expect(failure, isA<StoryPublicationFailed>());
    failure as StoryPublicationFailed;
    expect(failure.cause, same(refusal));
    expect(
      EventDeletionRefused.parse((failure.cause as EventFailure).message)
          ?.users,
      refusal.users,
    );
    expect(
      [for (final entry in failure.progress.saved) entry.id],
      [eventId(1)],
    );
    expect(failure.progress.failed?.entries.single.id, eventId(2));
    expect(
      [for (final entry in failure.progress.remaining) entry.id],
      [eventId(2), eventId(3)],
    );
    expect(port.calls, hasLength(2));
    expect(dirtyIds(port), [eventId(2), eventId(3)]);
    expect(port.project.eventRegistry!.records.map((record) => record.name), [
      'kept',
      'Event',
      'Event',
    ]);
  });

  test('a failed batch leaves only what was not saved dirty', () async {
    final port = batchPort(130);
    for (var index = 1; index <= 130; index++) {
      rename(port, index, 'renamed $index');
    }
    port.refuse = (call, changes) =>
        call == 2 ? const EventFailure('disk full') : null;

    final failure = await publish(port)
        .then<Object?>((_) => null, onError: (Object error) => error);

    expect(failure, isA<StoryPublicationFailed>());
    failure as StoryPublicationFailed;
    expect(failure.cause, isA<EventFailure>());
    expect('$failure', 'disk full');
    expect(failure.progress.saved, hasLength(128));
    expect(
      [for (final entry in failure.progress.remaining) entry.id],
      [eventId(129), eventId(130)],
    );
    expect(dirtyIds(port), [eventId(129), eventId(130)]);
    expect(draft.canUndo, isTrue);
  });

  test(
    'another kind in the plan is refused before anything is written',
    () async {
      final port = batchPort(1);
      rename(port, 1, 'renamed');
      draft.load(StoryDraftKind.scene, 'intro', null);
      draft.put(StoryDraftKind.scene, scene('intro'));
      final saved = reader.of(port.project);
      final before = draft.changes(saved);

      final failure = await publish(port)
          .then<Object?>((_) => null, onError: (Object error) => error);

      expect(failure, isA<StoryPublicationUnsupported>());
      expect((failure as StoryPublicationUnsupported).kinds, {
        StoryDraftKind.scene,
      });
      expect(port.calls, isEmpty);
      expect(landings, 0);
      expect(draft.changes(saved), before);
      expect(draft.isTouched(StoryDraftKind.scene, 'intro'), isTrue);
    },
  );
}
