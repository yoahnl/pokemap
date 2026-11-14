import 'package:map_core/map_core_domain.dart';

final talkSource = NarrativeEventSourceRef.entityInteract('map', 'npc');

String eventId(String suffix) =>
    'evt_01a16b62-614a-7000-8000-0000000000$suffix';

NarrativeEventRecord behaviourCase(
  String suffix, {
  int priority = 0,
  int order = 0,
  NarrativeEventSourceRef? source,
  bool enabled = true,
  bool always = false,
  NarrativeEventReusePolicy reuse = NarrativeEventReusePolicy.reusable,
  NarrativeEventParallelPolicy? parallel,
  bool legacy = false,
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: eventId(suffix),
    name: 'Case $suffix',
    source: source ?? talkSource,
    conditions: always
        ? const []
        : [NarrativeEventCondition.fact('fact_$suffix', true)],
    sceneId: 'scene_$suffix',
    reusePolicy: reuse,
    priority: priority,
    order: order,
    parallelPolicy: parallel,
  ),
  enabled: enabled,
  activeInLegacyMode: legacy,
);
