import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_preview.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_dialogue_status.dart';

class StoryDialogueLanguageFields extends StatelessWidget {
  const StoryDialogueLanguageFields({
    super.key,
    required this.form,
    required this.unitId,
    required this.language,
    required this.locales,
    this.fallback,
    required this.changed,
    required this.chooseLanguage,
    required this.enabled,
  });

  final DialogueLocalizationEditing form;
  final String unitId;
  final String? language;
  final List<String> locales;
  final String? fallback;
  final VoidCallback changed;
  final ValueChanged<String> chooseLanguage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: StudioMetrics.controlHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              form.sourceLocale?.toUpperCase() ??
                  l10n.dialogueCatalogUnlocalized,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        const SizedBox(height: StudioSpacing.xl),
        StudioDraftField(
          key: const ValueKey('dialogue-editor-source'),
          value: form.sourceText(unitId),
          label: l10n.dialogueEditorSource,
          lines: 6,
          enabled: enabled,
          onChanged: (value) {
            form.writeSource(unitId, value);
            changed();
          },
        ),
      ],
    );
    final target = language;
    final resolution = target == null || form.sourceLocale == null
        ? null
        : form.resolve(unitId, target, locales: locales, fallback: fallback);
    final translation = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('dialogue-editor-language'),
          label: l10n.dialogueCatalogPreviewLanguage,
          value: target ?? '',
          options: {
            if (target == null) '': l10n.dialogueEditorTranslation,
            for (final locale in locales)
              if (locale != form.sourceLocale) locale: locale.toUpperCase(),
          },
          onChanged: (value) {
            if (value.isNotEmpty) chooseLanguage(value);
          },
        ),
        const SizedBox(height: StudioSpacing.xl),
        StudioDraftField(
          key: const ValueKey('dialogue-editor-translation'),
          value: target == null ? '' : form.translationText(unitId, target),
          label: l10n.dialogueEditorTranslation,
          lines: 6,
          enabled: enabled && resolution != null,
          onChanged: (value) {
            if (target != null) {
              form.writeTranslation(unitId, target, value);
              changed();
            }
          },
        ),
        const SizedBox(height: StudioSpacing.m),
        if (resolution == null)
          Text(
            form.sourceLocale == null
                ? l10n.dialogueEditorLegacyHint
                : l10n.dialogueEditorNoLanguages,
          )
        else ...[
          Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              StoryDialogueStatus(
                preview: DialogueCatalogPreview(
                  texts: [resolution.text],
                  status: switch (resolution.status) {
                    DialogueTranslationStatus.source =>
                      DialogueCatalogStatus.source,
                    DialogueTranslationStatus.translated =>
                      DialogueCatalogStatus.translated,
                    DialogueTranslationStatus.missing =>
                      DialogueCatalogStatus.missing,
                    DialogueTranslationStatus.needsReview =>
                      DialogueCatalogStatus.needsReview,
                  },
                ),
              ),
              if (resolution.usedFallback)
                StudioBadge(
                  l10n.dialogueCatalogFallback(
                    resolution.textLocale.toUpperCase(),
                  ),
                  tone: StudioTone.warning,
                ),
              if (resolution.usedFallback && resolution.needsReview)
                StudioBadge(
                  l10n.dialogueCatalogNeedsReview,
                  tone: StudioTone.warning,
                ),
            ],
          ),
          if (resolution.usedFallback)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.s),
              child: SelectableText(resolution.text),
            ),
          if (resolution.needsReview &&
              !resolution.usedFallback &&
              target != null)
            StudioButton(
              key: const ValueKey('dialogue-editor-review'),
              label: l10n.dialogueEditorReview,
              variant: StudioButtonVariant.quiet,
              onPressed: enabled
                  ? () {
                      form.writeTranslation(
                        unitId,
                        target,
                        form.translationText(unitId, target),
                      );
                      changed();
                    }
                  : null,
            ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 640
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: source),
                const SizedBox(width: StudioSpacing.xxl),
                Expanded(child: translation),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                source,
                const SizedBox(height: StudioSpacing.xxl),
                translation,
              ],
            ),
    );
  }
}
