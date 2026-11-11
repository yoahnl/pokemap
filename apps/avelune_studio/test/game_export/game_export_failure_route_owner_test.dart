import 'package:avelune_studio/features/game_export/application/game_export_failure_route.dart';
import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'export failures reopen their own destination or mode before any workspace',
    () {
      for (final available in [true, false]) {
        expect(
          gameExportFailureRoute(
            StudioFailureOwner.exportDestination,
            workspaceAvailable: available,
          ),
          GameExportFailureRoute.chooseDestination,
        );
        expect(
          gameExportFailureRoute(
            StudioFailureOwner.exportMode,
            workspaceAvailable: available,
          ),
          GameExportFailureRoute.localTestMode,
        );
      }
    },
  );

  test(
    'other failure owners open their workspace only when routing exists',
    () {
      final others = StudioFailureOwner.values.where(
        (owner) =>
            owner != StudioFailureOwner.exportDestination &&
            owner != StudioFailureOwner.exportMode,
      );
      expect(others, isNotEmpty);
      for (final owner in others) {
        expect(
          gameExportFailureRoute(owner, workspaceAvailable: true),
          GameExportFailureRoute.ownerWorkspace,
        );
        expect(
          gameExportFailureRoute(owner, workspaceAvailable: false),
          isNull,
        );
      }
      expect(gameExportFailureRoute(null, workspaceAvailable: true), isNull);
    },
  );
}
