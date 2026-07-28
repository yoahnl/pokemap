import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';

void main() {
  group('MapActivationCoordinator', () {
    const coordinator = MapActivationCoordinator();

    test('activates a clean document immediately', () {
      expect(
        coordinator.plan(isDirty: false),
        MapActivationPlan.activate,
      );
    });

    test('treats a transient Border preview as unsaved authoring state', () {
      expect(
        coordinator.plan(
          isDirty: false,
          hasPendingPreview: true,
        ),
        MapActivationPlan.requiresDecision,
      );
    });

    test('requires an explicit decision for a dirty document', () {
      expect(
        coordinator.plan(isDirty: true),
        MapActivationPlan.requiresDecision,
      );
    });

    test('maps save, discard, and cancel to distinct plans', () {
      expect(
        coordinator.plan(
          isDirty: true,
          decision: DirtyMapActivationDecision.save,
        ),
        MapActivationPlan.saveThenActivate,
      );
      expect(
        coordinator.plan(
          isDirty: true,
          decision: DirtyMapActivationDecision.discard,
        ),
        MapActivationPlan.activate,
      );
      expect(
        coordinator.plan(
          isDirty: true,
          decision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationPlan.stay,
      );
    });

    test('ignores stale decisions when the document is already clean', () {
      expect(
        coordinator.plan(
          isDirty: false,
          decision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationPlan.activate,
      );
    });
  });
}
