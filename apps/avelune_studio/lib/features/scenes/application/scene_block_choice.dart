import 'package:map_core/map_core_domain.dart';

class SceneBlockChoice {
  const SceneBlockChoice({
    required this.kind,
    required this.label,
    this.payload,
  });
  final SceneNodeKind kind;
  final String label;
  final SceneNodePayload? payload;
}
