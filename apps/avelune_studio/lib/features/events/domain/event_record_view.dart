import 'package:map_core/map_core_domain.dart';

extension EventRecordView on NarrativeEventRecord {
  String get name => when(draft: (d) => d.name, configured: (d, _) => d.name);
  NarrativeEventSourceRef? get source =>
      when(draft: (d) => d.source, configured: (d, _) => d.source);
  String? get sceneId =>
      when(draft: (d) => d.sceneId, configured: (d, _) => d.sceneId);
  NarrativeEventConditionExpression get expression => when(
    draft: (d) => d.conditionExpression,
    configured: (d, _) => d.conditionExpression,
  );
  NarrativeEventReusePolicy? get reusePolicy =>
      when(draft: (d) => d.reusePolicy, configured: (d, _) => d.reusePolicy);
  NarrativeEventResetPolicy get resetPolicy =>
      when(draft: (d) => d.resetPolicy, configured: (d, _) => d.resetPolicy);
  int get priority =>
      when(draft: (d) => d.priority, configured: (d, _) => d.priority);
  int get order => when(draft: (d) => d.order, configured: (d, _) => d.order);
}
