import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../ui/design_system/design_system.dart';

const editorUpdateBannerDismissKey =
    ValueKey<String>('editor-update-banner-dismiss');
const editorUpdateBannerReadNotesKey =
    ValueKey<String>('editor-update-banner-read-notes');
const editorUpdateBannerInstallKey =
    ValueKey<String>('editor-update-banner-install');

/// Localized, non-modal presentation of an available editor release.
class EditorUpdateBanner extends StatelessWidget {
  const EditorUpdateBanner({
    super.key,
    required this.versionLabel,
    required this.onReadNotes,
    required this.onUpdate,
    required this.onDismiss,
  });

  final String versionLabel;
  final VoidCallback onReadNotes;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.pokeMapL10n;
    return KeyedSubtree(
      key: const ValueKey<String>('editor-update-available-banner'),
      child: PokeMapActionBanner(
        title: l10n.editorUpdateAvailableTitle,
        message: l10n.editorUpdateAvailableBody(versionLabel),
        tone: PokeMapTone.brand,
        dismissLabel: l10n.editorUpdateDismiss,
        onDismiss: onDismiss,
        dismissKey: editorUpdateBannerDismissKey,
        actions: [
          PokeMapActionBannerAction(
            key: editorUpdateBannerReadNotesKey,
            label: l10n.editorUpdateReadNotes,
            onPressed: onReadNotes,
            variant: PokeMapButtonVariant.secondary,
          ),
          PokeMapActionBannerAction(
            key: editorUpdateBannerInstallKey,
            label: l10n.editorUpdateInstall,
            onPressed: onUpdate,
          ),
        ],
      ),
    );
  }
}
