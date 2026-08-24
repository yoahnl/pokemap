import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';

void main() {
  group('editorAuthoringSecurityLimits', () {
    test('a sustained editing session is never rate limited', () {
      var now = DateTime.utc(2026, 8, 24, 22);
      final policy = AuthoringAuthorizationPolicy(
        confirmations: AuthoringConfirmationStore(clock: () => now),
        limits: editorAuthoringSecurityLimits,
        clock: () => now,
      );
      final actor = AuthoringActor(
        actorId: 'local_editor',
        permissions: const [AuthoringPermissionScope.projectWrite],
      );

      AuthoringAuthorizationRequest request() => AuthoringAuthorizationRequest(
            actor: actor,
            projectId: 'sustained_editing_session',
            operation: AuthoringSecurityOperation.apply,
            actionId: 'placed_element.batch_place',
            actionVersion: 1,
            riskLevel: AuthoringRiskLevel.low,
            requestBytes: 4096,
            touchedResources: 2,
          );

      // Ten minutes of placing elements at two clicks per second.
      for (var i = 0; i < 1200; i++) {
        now = now.add(const Duration(milliseconds: 500));
        expect(
          () => policy.authorize(request()),
          returnsNormally,
          reason: 'operation ${i + 1} was denied',
        );
      }
    });

    test('the request byte ceiling still covers a whole project manifest', () {
      expect(editorAuthoringSecurityLimits.maxRequestBytes, 64 << 20);
    });
  });
}
