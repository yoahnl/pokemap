import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';

/// Adding a Smart Tile layer used to surface the raw authoring code — an
/// author faced with a bare `plan.stale` chip has nothing to act on.
void main() {
  group('canonicalSmartTileLayerFailureMessage', () {
    test('explains a stale revision instead of printing its code', () {
      final message = canonicalSmartTileLayerFailureMessage(
        const EditorAuthoringMutationFailure(
          code: 'plan.stale',
          message: 'The project changed after this plan was created.',
        ),
      );

      expect(message, isNot(contains('plan.stale')));
      expect(message.toLowerCase(), contains('projet'));
      expect(message, contains('Réessayez'));
    });

    test('keeps the canonical message for other failures', () {
      final message = canonicalSmartTileLayerFailureMessage(
        const EditorAuthoringMutationFailure(
          code: 'smart_tile.preset_unpublished',
          message: 'Le preset n’est pas publié.',
        ),
      );

      expect(message, contains('Le preset n’est pas publié.'));
    });
  });
}
