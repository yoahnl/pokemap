import 'package:map_authoring/map_authoring_dialogue.dart';

class DialogueViewState {
  String? nodeId, stepId, branchId, wireId;
  bool previewOpen = true;
  String tab = 'properties';
  void select(String node, {String? step, String? branch}) {
    nodeId = node;
    stepId = step;
    branchId = branch;
    wireId = null;
  }

  void reconcile(DialogueEditorDocument document) {
    if (document.nodeById(nodeId ?? '') == null) {
      nodeId = document.nodes.firstOrNull?.id;
      stepId = null;
      branchId = null;
      wireId = null;
    }
  }

  void clearDeepestSelection() {
    if (wireId != null) {
      wireId = null;
    } else if (branchId != null) {
      branchId = null;
    } else if (stepId != null) {
      stepId = null;
    }
  }
}
