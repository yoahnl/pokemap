import '../models/project_manifest.dart';

String resolvePathAnimationTriggerRuleId(
  PathAnimationTriggerRule rule, {
  required int index,
}) {
  final id = rule.id.trim();
  if (id.isNotEmpty) {
    return id;
  }
  return 'rule_$index';
}
