import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_legacy_catalog.dart';
import 'event_labels.dart';

Future<void> showLegacyEventDetail(
  BuildContext context,
  EventLegacyEntry entry,
) => showDialog<void>(
  context: context,
  builder: (context) {
    final detail = entry.detail();
    return AlertDialog(
      title: Text(entry.name),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioNotice(
                'Historique · consultation seule. Cette entrée conserve son format et son exécution actuels. Aucune conversion ni activation automatique.',
              ),
              const SizedBox(height: 16),
              for (final line in detail.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line),
                ),
              if (detail.source != null)
                Text(
                  'Source : ${eventKindLabel(detail.source!.kind)} · ${eventTargetId(detail.source) ?? eventMapId(detail.source) ?? 'Globale'}',
                ),
              if (detail.diagnostics.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Points de vigilance de la projection'),
                for (final diagnostic in detail.diagnostics)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(diagnostic),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        StudioButton(
          label: 'Fermer la consultation',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  },
);
