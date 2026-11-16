import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_editing.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_dialogue_language_fields.dart';

class StoryDialogueEditor extends StatefulWidget {
  const StoryDialogueEditor({
    super.key,
    required this.catalog,
    required this.form,
  });
  final DialogueCatalogController catalog;
  final DialogueLocalizationEditing form;

  @override
  State<StoryDialogueEditor> createState() => _StoryDialogueEditorState();
}

class _StoryDialogueEditorState extends State<StoryDialogueEditor> {
  late String _unit = widget.form.localization.units.first.id;
  String? _language;
  bool _copying = false;
  late String _copyName = context.l10n.dialogueEditorCopyDefault(
    widget.form.base.entry.name,
  );
  String? _problem;

  List<String> get _targets => widget.catalog.locales
      .where((locale) => locale != widget.form.sourceLocale)
      .toList();

  @override
  void initState() {
    super.initState();
    final preferred = widget.catalog.language;
    _language = _targets.contains(preferred) ? preferred : _targets.firstOrNull;
  }

  void _changed() => setState(() => _problem = null);

  void _apply() {
    try {
      if (_copying) {
        widget.catalog.copyEditing(widget.form, _copyName);
      } else {
        widget.catalog.applyEditing(widget.form);
      }
      Navigator.pop(context);
    } on DialogueTextUnrepresentable {
      setState(() => _problem = context.l10n.dialogueEditorUnrepresentable);
    } on StateError {
      setState(() => _problem = context.l10n.dialogueEditorConflict);
    } on Object {
      setState(() => _problem = context.l10n.dialogueEditorError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = widget.form;
    final document = widget.catalog.document(form.base.id);
    final units = form.localization.units;
    final editable = widget.catalog.editing?.editable ?? false;
    final width = (MediaQuery.sizeOf(context).width - 120).clamp(280.0, 980.0);
    return StudioReviewDialog(
      title: form.base.entry.name,
      contentWidth: width,
      confirmLabel: _copying
          ? l10n.dialogueEditorCopy
          : l10n.dialogueEditorApply,
      cancelLabel: l10n.cancel,
      onConfirmed: editable ? _apply : null,
      onCancelled: () => Navigator.pop(context),
      secondaryActionLabel: _copying
          ? l10n.dialogueEditorOriginal
          : l10n.dialogueEditorCopy,
      onSecondaryAction: editable
          ? () => setState(() => _copying = !_copying)
          : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: StudioSpacing.m,
            children: [
              StudioBadge(
                l10n.dialogueCatalogSceneCount(document?.sceneIds.length ?? 0),
              ),
              for (final locale in widget.catalog.locales)
                StudioBadge(locale.toUpperCase()),
            ],
          ),
          if ((document?.sceneIds.length ?? 0) > 1)
            Padding(
              padding: const EdgeInsets.only(top: StudioSpacing.m),
              child: StudioNotice(l10n.dialogueEditorShared),
            ),
          if (_copying) ...[
            const SizedBox(height: StudioSpacing.l),
            StudioDraftField(
              key: const ValueKey('dialogue-editor-copy-name'),
              value: _copyName,
              label: l10n.dialogueEditorCopyName,
              onChanged: (value) => setState(() => _copyName = value),
            ),
            StudioNotice(l10n.dialogueEditorCopyHint),
          ],
          const SizedBox(height: StudioSpacing.xxl),
          if (form.base.entry.localization == null) ...[
            StudioSelect(
              key: const ValueKey('dialogue-editor-source-locale'),
              label: l10n.dialogueEditorSourceLocale,
              value: form.sourceLocale ?? '',
              options: {
                '': l10n.dialogueEditorChooseSource,
                for (final locale in widget.catalog.locales)
                  locale: locale.toUpperCase(),
              },
              onChanged: (value) {
                if (value.isEmpty) return;
                try {
                  form.declareSourceLocale(value);
                  if (!_targets.contains(_language)) {
                    _language = _targets.firstOrNull;
                  }
                  _changed();
                } on Object {
                  setState(() => _problem = l10n.dialogueEditorError);
                }
              },
            ),
            const SizedBox(height: StudioSpacing.l),
          ],
          if (units.length > 1) ...[
            StudioSelect(
              key: const ValueKey('dialogue-editor-unit'),
              label: l10n.dialogueEditorUnit,
              value: _unit,
              options: {
                for (final (index, unit) in units.indexed)
                  unit.id:
                      '${index + 1} · ${switch (unit.kind) {
                        DialogueTextKind.line => l10n.dialogueEditorLine,
                        DialogueTextKind.narration => l10n.dialogueEditorNarration,
                        DialogueTextKind.choice => l10n.dialogueEditorChoice,
                      }}',
              },
              onChanged: (id) => setState(() => _unit = id),
            ),
            const SizedBox(height: StudioSpacing.xl),
          ],
          StoryDialogueLanguageFields(
            form: form,
            unitId: _unit,
            language: _language,
            locales: widget.catalog.locales,
            fallback: widget.catalog.languages.value?.fallback,
            enabled: editable,
            changed: _changed,
            chooseLanguage: (value) => setState(() => _language = value),
          ),
          const SizedBox(height: StudioSpacing.xxl),
          Text(
            l10n.dialogueEditorDraftHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (form.sourceLocale != null && form.base.entry.localization == null)
            StudioNotice(l10n.dialogueEditorRuntimeHint),
          if (_problem case final problem?)
            StudioNotice(problem, isError: true),
        ],
      ),
    );
  }
}
