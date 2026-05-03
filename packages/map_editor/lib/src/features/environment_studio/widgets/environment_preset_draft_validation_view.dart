import 'package:flutter/cupertino.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';
import 'environment_preset_draft_presentation.dart';

/// Liste des issues de validation d’un brouillon (FR + message technique).
class EnvironmentPresetDraftValidationView extends StatelessWidget {
  const EnvironmentPresetDraftValidationView({
    super.key,
    required this.report,
    required this.labelColor,
    required this.subtleColor,
  });

  final EnvironmentPresetDraftValidationReport report;
  final Color labelColor;
  final Color subtleColor;

  @override
  Widget build(BuildContext context) {
    final err = report.errorCount;
    final warn = report.warningCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      key: const Key('environment-studio-draft-validation-root'),
      children: [
        Text(
          '$err erreur${err == 1 ? '' : 's'} · '
          '$warn avertissement${warn == 1 ? '' : 's'}',
          key: const Key('environment-studio-draft-validation-counts'),
          style: TextStyle(
            color: subtleColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (!report.hasIssues)
          Text(
            'Aucune anomalie détectée pour ce brouillon.',
            key: const Key('environment-studio-draft-validation-empty'),
            style: TextStyle(color: subtleColor, fontSize: 12.5),
          )
        else
          ...report.issues.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    key: Key('environment-studio-draft-issue-${e.key}'),
                    decoration: BoxDecoration(
                      color: EditorChrome.chipFill(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${environmentPresetDraftIssueSeverityLabel(e.value.severity)} — '
                            '${environmentPresetDraftIssueKindLabel(e.value.kind)}',
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value.message,
                            key: Key(
                              'environment-studio-draft-issue-msg-${e.key}',
                            ),
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
