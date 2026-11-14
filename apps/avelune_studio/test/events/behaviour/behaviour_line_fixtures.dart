import 'dart:convert';

import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

const lineUuids = [
  '01a16b62-614a-741c-be2e-18a338e7bcd6',
  '01a16b62-614a-7302-a9a2-0ab2445543de',
  '01a16b62-614a-7f70-bac5-2ba2474bc103',
];

BehaviourLineIdGenerator lineIdGenerator([List<String> uuids = lineUuids]) {
  var next = 0;
  return BehaviourLineIdGenerator(
    ids: NarrativeEventIdGenerator(rawUuidFactory: () => uuids[next++]),
  );
}

NarrativeEventRecord lineOwner(String sceneId, {String id = _eventId}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: 'Talk',
        source: NarrativeEventSourceRef.entityInteract('map', 'npc'),
        conditions: const [],
        sceneId: sceneId,
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );

const _eventId = 'evt_01a16b62-614a-7ee8-b422-3d1da534c818';

BehaviourLineDraft createdDraft(List<String> lines, {String? speakerId}) {
  final outcome = createBehaviourLine(
    ids: lineIdGenerator().generate(),
    name: 'Talk',
    lines: lines,
    speakerId: speakerId,
  );
  expect(outcome, isA<BehaviourLineAccepted<BehaviourLineDraft>>());
  return (outcome as BehaviourLineAccepted<BehaviourLineDraft>).value;
}

BehaviourLineReading readLine(
  SceneAsset scene,
  NarrativeDialogueSource? dialogue, {
  List<NarrativeEventRecord>? owners,
}) => readBehaviourLine(
  scene: scene,
  behaviours: owners ?? [lineOwner(scene.id)],
  dialogue: dialogue,
);

NarrativeDialogueSource storedDialogue(NarrativeDialogueSource source) =>
    NarrativeDialogueSource(
      entry: ProjectDialogueEntry.fromJson(
        jsonDecode(jsonEncode(source.entry.toJson())) as Map<String, dynamic>,
      ),
      source: utf8.decode(utf8.encode(source.source)),
      revision: source.revision,
    );
