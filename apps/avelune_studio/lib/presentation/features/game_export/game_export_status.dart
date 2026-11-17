import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameExportStatus extends StatelessWidget {
  const GameExportStatus({super.key, required this.port});
  final StudioGameExportPort port;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = switch (port.stage) {
      StudioExportStage.preparing => l10n.exportPreparing,
      StudioExportStage.building => l10n.exportBuilding,
      StudioExportStage.writing => l10n.exportWriting,
      StudioExportStage.cancelled when port.operationActive =>
        l10n.exportCancelling,
      _ => null,
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (progress != null) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: StudioSpacing.m),
            Text(progress),
          ],
          if (port.stage == StudioExportStage.cancelled &&
              !port.operationActive)
            StudioNotice(l10n.exportCancelled),
          if (port.stage == StudioExportStage.completed) ...[
            StudioNotice(l10n.exportCompleted),
            if (port.outputPath case final path?) SelectableText(path),
            if (port.warning case final warning?) StudioNotice(warning),
          ],
          if (port.stage == StudioExportStage.failed) ...[
            StudioNotice(
              port.failure?.summary ?? port.error ?? l10n.exportFailed,
              isError: true,
            ),
            if (port.failure?.detail ?? port.error case final detail?)
              ExpansionTile(
                title: Text(l10n.exportDetails),
                children: [SelectableText(detail)],
              ),
          ],
        ],
      ),
    );
  }
}
