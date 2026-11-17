import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_preview.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_preview.dart';
import 'package:avelune_studio/presentation/features/story/dialogues/story_dialogue_status.dart';
import 'package:avelune_studio/presentation/features/story/story_dialogue_link.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourScene extends StatefulWidget {
  const GameBehaviourScene({
    super.key,
    required this.binding,
    required this.record,
    required this.element,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final MapStoryElement element;
  final bool editable;

  @override
  State<GameBehaviourScene> createState() => _GameBehaviourSceneState();
}

class _GameBehaviourSceneState extends State<GameBehaviourScene> {
  String _language = 'source';
  Future<DialogueCatalogLanguages> Function()? _readLanguages;
  Future<DialogueCatalogLanguages>? _languages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final read = StoryDialogueNavigation.of(context)?.loadLanguages;
    if (_readLanguages != read) {
      _readLanguages = read;
      _languages = read?.call();
    }
  }

  Future<void> _create() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateScene(),
    );
    if (!mounted || text == null) return;
    widget.binding.writeLine(widget.element, widget.record, text);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DialogueCatalogLanguages>(
    future: _languages,
    builder: (context, snapshot) =>
        _content(context, snapshot.data, unavailable: snapshot.hasError),
  );

  Widget _content(
    BuildContext context,
    DialogueCatalogLanguages? languages, {
    required bool unavailable,
  }) {
    final l10n = context.l10n;
    final binding = widget.binding;
    final record = widget.record;
    final project = binding.behaviours.project(binding.project!);
    final scenes = [...project.scenes]
      ..sort((a, b) => a.name.compareTo(b.name));
    final scene = record.sceneId == null
        ? null
        : binding.sceneOf(record.sceneId!);
    final dialogueId = scene == null ? null : behaviourLineDialogueId(scene);
    final line = dialogueId == null ? null : binding.lineOf(record);
    final dialogue = dialogueId == null
        ? null
        : binding.behaviours.draft.effective(
            StoryDraftKind.dialogue,
            dialogueId,
            binding.behaviours.saved(binding.project!),
          );
    final localization = dialogue?.entry.localization;
    final locales = <String>{
      ...?languages?.locales,
      if (localization != null) localization.sourceLocale,
      for (final unit in localization?.units ?? const <DialogueTextUnit>[])
        ...unit.translations.keys,
    };
    final language = _language == 'source' || locales.contains(_language)
        ? _language
        : 'source';
    final preview = dialogue == null
        ? null
        : previewDialogue(
            dialogue,
            language,
            languages?.locales.isNotEmpty == true
                ? languages!
                : DialogueCatalogLanguages(
                    locales: locales.toList(),
                    fallback: localization?.sourceLocale,
                  ),
          );
    final open = binding.openScene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('map-story-then'),
          label: l10n.storyThenField,
          value: record.sceneId ?? '',
          options: {
            '': l10n.storySceneMissing,
            if (record.sceneId != null && scene == null)
              record.sceneId!: l10n.triggersUnavailable,
            for (final scene in scenes) scene.id: scene.name,
          },
          onChanged: widget.editable
              ? (value) =>
                    binding.setScene(record, value.isEmpty ? null : value)
              : null,
        ),
        if (scene != null) ...[
          const SizedBox(height: StudioSpacing.s),
          if (open != null)
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                key: const ValueKey('map-story-scene-open'),
                variant: StudioButtonVariant.secondary,
                icon: Icons.account_tree_outlined,
                label: l10n.sceneGraphOpen,
                onPressed: () => open(scene.id, record.id),
              ),
            ),
          if (dialogueId == null)
            SceneGraphPreview(
              scene: scene,
              project: project,
              onOpen: open == null ? null : () => open(scene.id, record.id),
            ),
        ],
        if (dialogueId != null) ...[
          const SizedBox(height: StudioSpacing.m),
          Text(
            l10n.triggersPreview,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (unavailable)
            StudioNotice(l10n.dialogueCatalogLanguagesUnavailable),
          if (_readLanguages != null)
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                key: const ValueKey('story-trigger-preview-refresh'),
                label: l10n.triggersPreviewRefresh,
                icon: Icons.refresh,
                variant: StudioButtonVariant.quiet,
                onPressed: () => setState(() {
                  _languages = _readLanguages!();
                }),
              ),
            ),
          if (preview == null)
            StudioNotice(
              line?.state == MapStoryLineState.unavailable
                  ? l10n.storyLineUnavailable(line?.problem ?? '')
                  : l10n.storyLineLoading,
            )
          else ...[
            StudioSelect(
              key: const ValueKey('story-trigger-preview-language'),
              label: l10n.triggersPreviewLanguage,
              value: language,
              options: {
                'source': l10n.dialogueCatalogSource,
                for (final locale in locales) locale: locale.toUpperCase(),
              },
              onChanged: (value) => setState(() => _language = value),
            ),
            Wrap(
              spacing: StudioSpacing.s,
              runSpacing: StudioSpacing.xs,
              children: [
                StoryDialogueStatus(preview: preview),
                if (preview.fallback)
                  StudioBadge(
                    l10n.dialogueCatalogFallback(
                      preview.textLocales.join(', ').toUpperCase(),
                    ),
                    tone: StudioTone.warning,
                  ),
              ],
            ),
            for (final text in preview.texts)
              Padding(
                padding: const EdgeInsets.only(top: StudioSpacing.xs),
                child: Text(text),
              ),
          ],
          StoryDialogueLink(id: dialogueId, label: l10n.dialogueEditorOpen),
        ],
        if (record.sceneId == null) ...[
          const SizedBox(height: StudioSpacing.s),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('story-trigger-scene-create'),
              icon: Icons.add,
              variant: StudioButtonVariant.secondary,
              label: l10n.triggersSceneCreate,
              onPressed: widget.editable ? _create : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _CreateScene extends StatefulWidget {
  const _CreateScene();

  @override
  State<_CreateScene> createState() => _CreateSceneState();
}

class _CreateSceneState extends State<_CreateScene> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.triggersSceneCreate),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.triggersSceneCreateHint),
            const SizedBox(height: StudioSpacing.m),
            StudioDraftField(
              key: const ValueKey('story-trigger-scene-text'),
              value: _text,
              label: l10n.triggersSceneFirstText,
              lines: 4,
              onChanged: (value) => setState(() => _text = value),
            ),
          ],
        ),
      ),
      actions: [
        StudioButton(
          label: l10n.cancel,
          variant: StudioButtonVariant.quiet,
          onPressed: () => Navigator.pop(context),
        ),
        StudioButton(
          key: const ValueKey('story-trigger-scene-confirm'),
          label: l10n.triggersSceneCreate,
          onPressed: _text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _text),
        ),
      ],
    );
  }
}
