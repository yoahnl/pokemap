import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';

/// Canonical Smart Tile failures used to surface raw authoring codes. An author
/// facing a bare `plan.stale` or `authoring.unexpected_failure` chip has nothing
/// to act on — least of all the one case that is trivially recoverable, where
/// the document on disk simply moved ahead of the open session.
void main() {
  group('canonicalSmartTileFailureMessage', () {
    test('explains a stale revision instead of printing its code', () {
      final message = canonicalSmartTileFailureMessage(
        const EditorAuthoringMutationFailure(
          code: 'plan.stale',
          message: 'The project changed after this plan was created.',
        ),
      );

      expect(message, isNot(contains('plan.stale')));
      expect(message.toLowerCase(), contains('projet'));
      expect(message, contains('Réessayez'));
    });

    test('turns an unexpected failure into reload guidance', () {
      final message = canonicalSmartTileFailureMessage(
        const EditorAuthoringMutationFailure(
          code: 'authoring.unexpected_failure',
          message: 'Bad state: something deep failed',
        ),
      );

      expect(message, isNot(contains('authoring.unexpected_failure')));
      expect(message.toLowerCase(), contains('recharg'));
      expect(editorErrorRequiresReload(message), isTrue);
    });

    test('flags the explicit reload-required code', () {
      final message = canonicalSmartTileFailureMessage(
        const EditorAuthoringMutationFailure(
          code: 'smart_tile.cell.reload_required',
          message: 'reload required',
        ),
      );

      expect(editorErrorRequiresReload(message), isTrue);
      expect(message.toLowerCase(), contains('recharg'));
    });

    test('keeps the canonical message for other failures', () {
      final message = canonicalSmartTileFailureMessage(
        const EditorAuthoringMutationFailure(
          code: 'smart_tile.preset_unpublished',
          message: 'Le preset n’est pas publié.',
        ),
      );

      expect(message, contains('Le preset n’est pas publié.'));
      expect(editorErrorRequiresReload(message), isFalse);
    });

    test('does not ask to reload for an unrelated message or none at all', () {
      expect(editorErrorRequiresReload(null), isFalse);
      expect(editorErrorRequiresReload('Carte enregistrée'), isFalse);
    });
  });
}
