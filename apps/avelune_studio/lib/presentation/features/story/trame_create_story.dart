import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'trame_labels.dart';

Future<String?> showTrameCreateStory(
  BuildContext context,
  StorylineTrameController trame,
) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _TrameCreateStory(trame: trame),
);

class _TrameCreateStory extends StatefulWidget {
  const _TrameCreateStory({required this.trame});
  final StorylineTrameController trame;

  @override
  State<_TrameCreateStory> createState() => _TrameCreateStoryState();
}

class _TrameCreateStoryState extends State<_TrameCreateStory> {
  final _title = TextEditingController();
  final _chapter = TextEditingController();
  var _type = StorylineType.main;
  var _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _chapter.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _saving = true);
    final before = {
      for (final story
          in widget.trame.view?.outline.storylines ??
              const <StorylineOutlineStoryline>[])
        story.id,
    };
    final saved = await widget.trame.startStoryline(
      _type,
      _title.text.trim(),
      _chapter.text.trim(),
    );
    if (!mounted) return;
    if (saved) {
      final id = widget.trame.view?.outline.storylines
          .where((story) => !before.contains(story.id))
          .firstOrNull
          ?.id;
      Navigator.of(context).pop(id);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StudioReviewDialog(
      key: const ValueKey('trame-create-story'),
      title: l10n.trameCreateStory,
      confirmLabel: l10n.trameCreateStory,
      cancelLabel: l10n.memoryCancel,
      onCancelled: _saving ? () {} : () => Navigator.of(context).pop(),
      onConfirmed:
          !_saving &&
              _title.text.trim().isNotEmpty &&
              _chapter.text.trim().isNotEmpty
          ? _create
          : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('trame-create-title'),
            controller: _title,
            autofocus: true,
            enabled: !_saving,
            decoration: InputDecoration(labelText: l10n.trameStorylineName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: StudioSpacing.l),
          KeyedSubtree(
            key: const ValueKey('trame-create-type'),
            child: StudioSelect(
              label: l10n.trameStoryTypeLabel,
              value: _type.name,
              options: {
                for (final type in StorylineType.values)
                  type.name: l10n.trameType(type),
              },
              onChanged: _saving
                  ? null
                  : (value) => setState(
                      () => _type = StorylineType.values.byName(value),
                    ),
            ),
          ),
          const SizedBox(height: StudioSpacing.l),
          TextField(
            key: const ValueKey('trame-create-chapter'),
            controller: _chapter,
            enabled: !_saving,
            decoration: InputDecoration(labelText: l10n.trameFirstChapter),
            onChanged: (_) => setState(() {}),
          ),
          if (widget.trame.refusal case final code?)
            StudioNotice(l10n.trameRefused(code), isError: true),
        ],
      ),
    );
  }
}
