import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

String _id(int number) =>
    'evt_019abcde-0000-7000-8000-${number.toString().padLeft(12, '0')}';

NarrativeEventRecord _record(
  int number,
  String name, {
  NarrativeEventSourceRef? source,
  int priority = 0,
  int order = 0,
  bool legacy = false,
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: _id(number),
    name: name,
    source: source ?? NarrativeEventSourceRef.mapEnter('town'),
    conditions: const [],
    sceneId: 'scene_$number',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: priority,
    order: order,
    resetPolicy: const NarrativeEventResetPolicy.never(),
  ),
  enabled: true,
  activeInLegacyMode: legacy,
);

List<String> _names(Iterable<NarrativeEventRecord> records) => [
  for (final record in records) record.definitionOrNull!.name,
];

void main() {
  final source = NarrativeEventSourceRef.mapEnter('town');

  test('candidates follow priority, then order, then identity', () {
    final records = [
      _record(3, 'Troisième', order: 1),
      _record(2, 'Prioritaire', priority: 5),
      _record(1, 'Deuxième', order: 1),
      _record(4, 'Premier ordre'),
      _record(5, 'Ailleurs', source: NarrativeEventSourceRef.mapEnter('cave')),
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: _id(6),
          name: 'Brouillon',
          source: source,
          conditions: const [],
          priority: 9,
          order: 0,
        ),
      ),
    ];

    expect(
      _names(
        narrativeEventDispatchCandidates(
          records,
          source,
          EventSystemMode.v2Only,
        ),
      ),
      ['Prioritaire', 'Premier ordre', 'Deuxième', 'Troisième'],
    );
  });

  test('the historical mode only keeps events active in that mode', () {
    final records = [
      _record(1, 'Moderne'),
      _record(2, 'Historique', legacy: true),
    ];

    expect(
      _names(
        narrativeEventDispatchCandidates(
          records,
          source,
          EventSystemMode.legacyOnly,
        ),
      ),
      ['Historique'],
    );
  });
}
