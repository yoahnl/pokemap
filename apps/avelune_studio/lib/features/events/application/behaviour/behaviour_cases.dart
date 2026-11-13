import 'package:map_core/map_core_domain.dart';

import '../../domain/event_record_view.dart';
import 'behaviour_record_edit.dart';

enum BehaviourCaseState { tried, draft, disabled, parallel, outsideLegacyMode }

final class BehaviourCase {
  const BehaviourCase(this.record, this.state);

  final NarrativeEventRecord record;
  final BehaviourCaseState state;
}

final class BehaviourCaseGroup {
  BehaviourCaseGroup(this.source, List<BehaviourCase> cases)
    : cases = List.unmodifiable(cases);

  final NarrativeEventSourceRef source;
  final List<BehaviourCase> cases;

  NarrativeEventSourceKind get kind => source.kind;

  List<NarrativeEventRecord> get records => [
    for (final item in cases) item.record,
  ];
}

final class BehaviourCaseShadow {
  const BehaviourCaseShadow({required this.caseId, required this.shadowedBy});

  final String caseId;
  final String shadowedBy;
}

List<BehaviourCaseGroup> behaviourCaseGroups(
  Iterable<NarrativeEventRecord> behaviours,
  EventSystemMode mode,
) {
  final bySource = <NarrativeEventSourceRef, List<NarrativeEventRecord>>{};
  for (final record in behaviours) {
    final source = record.source;
    if (source != null) bySource.putIfAbsent(source, () => []).add(record);
  }
  final sources = bySource.keys.toList()
    ..sort((left, right) => left.kind.index.compareTo(right.kind.index));
  return [
    for (final source in sources)
      BehaviourCaseGroup(source, [
        for (final record in _engineOrder(bySource[source]!, source))
          BehaviourCase(record, _state(record, mode)),
      ]),
  ];
}

List<NarrativeEventRecord> moveBehaviourCase(
  List<NarrativeEventRecord> cases,
  int from,
  int to,
) {
  RangeError.checkValidIndex(from, cases, 'from');
  RangeError.checkValidIndex(to, cases, 'to');
  final source = cases.first.source;
  if (source == null ||
      cases.any((record) => record.source != source) ||
      !_sameIds(_engineOrder(cases, source), cases)) {
    throw ArgumentError.value(cases, 'cases');
  }
  if (from == to) return const [];
  final moved = cases[from];
  final target = [...cases]
    ..removeAt(from)
    ..insert(to, moved);
  final before = to == 0 ? null : target[to - 1];
  final after = to == target.length - 1 ? null : target[to + 1];
  final fits =
      (before == null || before.priority >= moved.priority) &&
      (after == null || moved.priority >= after.priority);
  final priority = fits
      ? moved.priority
      : to > from
      ? (before ?? after!).priority
      : (after ?? before!).priority;
  final group = [
    for (final record in target)
      if (identical(record, moved) || record.priority == priority) record,
  ];
  final orders = _orders(group, group.indexOf(moved), priority);
  return [
    for (final record in group)
      if (identical(record, moved)
          ? priority != moved.priority || orders[record.id] != moved.order
          : orders[record.id] != record.order)
        editBehaviourRecord(
          record,
          priority: identical(record, moved) ? priority : null,
          order: orders[record.id],
        ),
  ];
}

List<BehaviourCaseShadow> shadowedBehaviourCases(
  BehaviourCaseGroup group, {
  required Set<String> uncertainIds,
}) {
  if (group.kind == NarrativeEventSourceKind.entityAutorun) return const [];
  NarrativeEventRecord? mask;
  final shadows = <BehaviourCaseShadow>[];
  for (final item in group.cases) {
    if (item.state == BehaviourCaseState.parallel ||
        item.state == BehaviourCaseState.outsideLegacyMode) {
      continue;
    }
    if (mask != null) {
      shadows.add(
        BehaviourCaseShadow(caseId: item.record.id, shadowedBy: mask.id),
      );
    } else if (item.state == BehaviourCaseState.tried &&
        _alwaysPlays(item.record) &&
        !uncertainIds.contains(item.record.id)) {
      mask = item.record;
    }
  }
  return shadows;
}

bool _alwaysPlays(NarrativeEventRecord record) {
  final expression = record.expression;
  return record.reusePolicy == NarrativeEventReusePolicy.reusable &&
      expression is NarrativeEventConditionAll &&
      expression.children.isEmpty;
}

BehaviourCaseState _state(NarrativeEventRecord record, EventSystemMode mode) {
  if (record.definitionOrNull == null) return BehaviourCaseState.draft;
  if (mode == EventSystemMode.legacyOnly && !record.activeInLegacyMode) {
    return BehaviourCaseState.outsideLegacyMode;
  }
  if (record.parallelPolicy != null) return BehaviourCaseState.parallel;
  return record.enabledOrNull == true
      ? BehaviourCaseState.tried
      : BehaviourCaseState.disabled;
}

List<NarrativeEventRecord> _engineOrder(
  List<NarrativeEventRecord> records,
  NarrativeEventSourceRef source,
) {
  final byId = {for (final record in records) record.id: record};
  final ranked = narrativeEventDispatchCandidates(
    [
      for (final record in records)
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: record.id,
            name: record.name,
            source: source,
            conditions: const [],
            sceneId: record.id,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: record.priority,
            order: record.order,
          ),
          enabled: false,
        ),
    ],
    source,
    EventSystemMode.v2Only,
  );
  return [for (final rank in ranked) byId[rank.id]!];
}

Map<String, int> _orders(
  List<NarrativeEventRecord> group,
  int index,
  int priority,
) {
  final moved = group[index];
  final room = [
    for (final (position, record) in group.indexed) record.order - position,
  ];
  final kept = List<(int, int)>.filled(group.length, (0, 0));
  final previous = List<int?>.filled(group.length, null);
  int? last;
  for (var i = 0; i < group.length; i++) {
    if (room[i] < 0) continue;
    final own = (1, identical(group[i], moved) ? 0 : 1);
    kept[i] = own;
    for (var j = 0; j < i; j++) {
      if (room[j] < 0 || room[j] > room[i]) continue;
      final longer = (kept[j].$1 + own.$1, kept[j].$2 + own.$2);
      if (_better(longer, kept[i])) {
        kept[i] = longer;
        previous[i] = j;
      }
    }
    if (last == null || _better(kept[i], kept[last])) last = i;
  }
  final keep = <int>{};
  for (var at = last; at != null; at = previous[at]) {
    keep.add(at);
  }
  final orders = <String, int>{};
  int? before;
  for (var i = 0; i < group.length; i++) {
    if (keep.contains(i)) {
      before = i;
      orders[group[i].id] = group[i].order;
      continue;
    }
    final anchor = before ?? keep.where((at) => at > i).firstOrNull;
    orders[group[i].id] = (anchor == null ? 0 : room[anchor]) + i;
  }
  final ranked = _engineOrder([
    for (final record in group)
      editBehaviourRecord(
        record,
        priority: identical(record, moved) ? priority : null,
        order: orders[record.id],
      ),
  ], moved.source!);
  if (!_sameIds(ranked, group)) throw StateError('behaviourCaseOrder');
  return orders;
}

bool _better((int, int) left, (int, int) right) =>
    left.$1 > right.$1 || (left.$1 == right.$1 && left.$2 > right.$2);

bool _sameIds(
  List<NarrativeEventRecord> left,
  List<NarrativeEventRecord> right,
) {
  for (var i = 0; i < left.length; i++) {
    if (left[i].id != right[i].id) return false;
  }
  return true;
}
