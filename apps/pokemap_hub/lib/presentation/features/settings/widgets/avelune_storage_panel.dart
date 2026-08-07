import 'package:flutter/material.dart';

import '../avelune_theme.dart';

/// Storage figures for the console, projected from the real dashboard snapshot.
///
/// Only what is actually measured is shown. `HubStorageSnapshot.availableBytes`
/// is nullable because the platform cannot always report free space, and in that
/// case the row is omitted rather than filled with a guess.
class AveluneStoragePanel extends StatelessWidget {
  const AveluneStoragePanel({
    super.key,
    required this.gameCount,
    required this.usedLabel,
    this.availableLabel,
  });

  final int gameCount;
  final String usedLabel;
  final String? availableLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final french = Localizations.maybeLocaleOf(context)?.languageCode == 'fr';

    return Column(
      key: const ValueKey<String>('avelune-storage-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StorageRow(
          icon: AveluneIcons.game,
          label: french ? 'Jeux installés' : 'Installed games',
          value: '$gameCount',
        ),
        const SizedBox(height: AveluneSpacing.sm),
        _StorageRow(
          icon: AveluneIcons.storageUsed,
          label: french ? 'Espace utilisé' : 'Space used',
          value: usedLabel,
        ),
        if (availableLabel case final available?) ...<Widget>[
          const SizedBox(height: AveluneSpacing.sm),
          _StorageRow(
            icon: AveluneIcons.storageFree,
            label: french ? 'Espace disponible' : 'Space available',
            value: available,
          ),
        ] else ...<Widget>[
          const SizedBox(height: AveluneSpacing.md),
          Text(
            french
                ? 'L’espace disponible n’est pas mesurable sur cet appareil.'
                : 'Free space cannot be measured on this device.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: AveluneSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
