import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class SceneCinematicPickerDialog extends StatelessWidget {
  const SceneCinematicPickerDialog({
    super.key,
    required this.library,
    this.title = 'Choisir une cinématique',
  });

  final CinematicsLibraryReadModel library;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      key: const ValueKey('scene-cinematic-picker-dialog'),
      title: Text(title),
      content: SizedBox(
        width: 390,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              for (final entry in library.canonicalEntries)
                _CinematicPickerEntryButton(entry: entry),
              if (library.bridgeEntries.isNotEmpty) ...[
                const SizedBox(height: 8),
                const PokeMapBadge(
                  label: 'Bridges legacy',
                  variant: PokeMapBadgeVariant.warning,
                ),
                const SizedBox(height: 8),
                for (final entry in library.bridgeEntries)
                  _CinematicPickerBridgeCard(entry: entry),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _CinematicPickerEntryButton extends StatelessWidget {
  const _CinematicPickerEntryButton({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        key: ValueKey(
            'scene-cinematic-picker-option-${_pickerKeyPart(entry.id)}'),
        onTap: () => Navigator.of(context).pop(entry),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: _CinematicPickerEntryContent(
          entry: entry,
          badge: const PokeMapBadge(
            label: 'CinematicAsset',
            variant: PokeMapBadgeVariant.success,
          ),
        ),
      ),
    );
  }
}

class _CinematicPickerBridgeCard extends StatelessWidget {
  const _CinematicPickerBridgeCard({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PokeMapCard(
        key: ValueKey(
            'scene-cinematic-picker-bridge-${_pickerKeyPart(entry.id)}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: _CinematicPickerEntryContent(
          entry: entry,
          badge: const PokeMapBadge(
            label: 'Legacy',
            variant: PokeMapBadgeVariant.warning,
          ),
        ),
      ),
    );
  }
}

class _CinematicPickerEntryContent extends StatelessWidget {
  const _CinematicPickerEntryContent({
    required this.entry,
    required this.badge,
  });

  final CinematicsLibraryEntry entry;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final details = [
      entry.id,
      if (entry.mapId != null) 'Map: ${entry.mapId}',
      if (entry.storylineId != null) 'Storyline: ${entry.storylineId}',
      if (entry.chapterId != null) 'Chapitre: ${entry.chapterId}',
      '${entry.timeline.stepCount} step(s)',
      '${entry.requiredActors.length} acteur(s)',
      if (entry.timeline.isEmpty) 'Timeline vide',
      if (entry.usages.isNotEmpty) '${entry.usages.length} scène(s)',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            badge,
          ],
        ),
        const SizedBox(height: 4),
        for (final detail in details)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        for (final diagnostic in entry.diagnostics)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PokeMapBadge(
                  label: _labelForDiagnostic(diagnostic.severity),
                  variant: _variantForDiagnostic(diagnostic.severity),
                ),
                const SizedBox(height: 2),
                Text(
                  diagnostic.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

PokeMapBadgeVariant _variantForDiagnostic(
  CinematicsLibraryDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicsLibraryDiagnosticSeverity.error => PokeMapBadgeVariant.error,
    CinematicsLibraryDiagnosticSeverity.warning => PokeMapBadgeVariant.warning,
    CinematicsLibraryDiagnosticSeverity.info => PokeMapBadgeVariant.info,
  };
}

String _labelForDiagnostic(CinematicsLibraryDiagnosticSeverity severity) {
  return switch (severity) {
    CinematicsLibraryDiagnosticSeverity.error => 'Erreur',
    CinematicsLibraryDiagnosticSeverity.warning => 'Warning',
    CinematicsLibraryDiagnosticSeverity.info => 'Info',
  };
}

String _pickerKeyPart(String value) {
  final buffer = StringBuffer();
  for (final codeUnit in value.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isUpper = codeUnit >= 65 && codeUnit <= 90;
    final isLower = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isUpper || isLower) {
      buffer.writeCharCode(codeUnit);
    } else if (buffer.isNotEmpty && !buffer.toString().endsWith('_')) {
      buffer.write('_');
    }
  }
  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}
