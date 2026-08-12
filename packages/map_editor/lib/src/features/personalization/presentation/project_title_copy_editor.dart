import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'personalization_deferred_commit.dart';

class ProjectTitleCopyEditor extends StatefulWidget {
  const ProjectTitleCopyEditor({
    super.key,
    required this.profile,
    required this.projectName,
    required this.onChanged,
    this.onPreviewChanged,
    this.commitCoordinator,
  });

  final ProjectTitlePresentationProfile? profile;
  final String projectName;
  final ValueChanged<ProjectTitlePresentationProfile?> onChanged;
  final ValueChanged<ProjectTitlePresentationProfile?>? onPreviewChanged;
  final PersonalizationDeferredCommitCoordinator? commitCoordinator;

  @override
  State<ProjectTitleCopyEditor> createState() => _ProjectTitleCopyEditorState();
}

class _ProjectTitleCopyEditorState extends State<ProjectTitleCopyEditor> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _prompt;
  late final List<FocusNode> _focusNodes;
  late final PersonalizationDeferredCommit _commit;
  late bool _titleFallback;
  late bool _subtitleFallback;
  late bool _promptFallback;

  @override
  void initState() {
    super.initState();
    _commit = PersonalizationDeferredCommit(widget.commitCoordinator);
    _title = TextEditingController(text: widget.profile?.title ?? '');
    _subtitle = TextEditingController(text: widget.profile?.subtitle ?? '');
    _prompt = TextEditingController(text: widget.profile?.prompt ?? '');
    _focusNodes = List<FocusNode>.generate(3, (_) => FocusNode());
    for (final node in _focusNodes) {
      node.addListener(_flushWhenFocusLeaves);
    }
    _titleFallback = widget.profile?.title == null;
    _subtitleFallback = widget.profile?.subtitle == null;
    _promptFallback = widget.profile?.prompt == null;
  }

  @override
  void didUpdateWidget(covariant ProjectTitleCopyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_commit.hasPending) return;
    if (oldWidget.profile == widget.profile &&
        oldWidget.projectName == widget.projectName) {
      return;
    }
    _synchronize();
  }

  @override
  void dispose() {
    _commit.flush();
    _commit.dispose();
    for (final node in _focusNodes) {
      node
        ..removeListener(_flushWhenFocusLeaves)
        ..dispose();
    }
    _title.dispose();
    _subtitle.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PokeMapSectionHeader(
            title: 'Textes affichés',
            description:
                'Le titre peut reprendre le nom du projet. Un sous-titre ou '
                'une invitation vide masque volontairement cette ligne.',
          ),
          const SizedBox(height: 8),
          PokeMapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PokeMapTextField(
                  label: 'Titre du jeu',
                  fieldKey: const ValueKey<String>('title-copy-title'),
                  controller: _title,
                  focusNode: _focusNodes[0],
                  hintText: 'Par défaut : ${widget.projectName}',
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(
                      projectTitleCopyMaxLength,
                    ),
                  ],
                  maxLines: projectTitleMaxLines,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) {
                    _titleFallback = false;
                    _previewAndSchedule();
                  },
                ),
                const SizedBox(height: 8),
                _fallbackButton(
                  key: const ValueKey<String>(
                    'title-copy-use-project-name',
                  ),
                  label: 'Utiliser le nom du projet',
                  selected: _titleFallback,
                  onPressed: () {
                    setState(() {
                      _titleFallback = true;
                      _title.clear();
                    });
                    _publish();
                  },
                ),
                const SizedBox(height: 16),
                PokeMapTextField(
                  label: 'Sous-titre',
                  fieldKey: const ValueKey<String>('title-copy-subtitle'),
                  controller: _subtitle,
                  focusNode: _focusNodes[1],
                  hintText: 'Par défaut : auteur ou studio du projet',
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(
                      projectTitleSubtitleMaxLength,
                    ),
                  ],
                  maxLines: projectTitleSubtitleMaxLines,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) {
                    _subtitleFallback = false;
                    _previewAndSchedule();
                  },
                ),
                const SizedBox(height: 8),
                _fallbackButton(
                  key: const ValueKey<String>('title-copy-use-author'),
                  label: 'Utiliser l’auteur du projet',
                  selected: _subtitleFallback,
                  onPressed: () {
                    setState(() {
                      _subtitleFallback = true;
                      _subtitle.clear();
                    });
                    _publish();
                  },
                ),
                const SizedBox(height: 16),
                PokeMapTextField(
                  label: 'Invitation',
                  fieldKey: const ValueKey<String>('title-copy-prompt'),
                  controller: _prompt,
                  focusNode: _focusNodes[2],
                  hintText: 'Par défaut : description du projet',
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(
                      projectTitlePromptMaxLength,
                    ),
                  ],
                  maxLines: projectTitlePromptMaxLines,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) {
                    _promptFallback = false;
                    _previewAndSchedule();
                  },
                ),
                const SizedBox(height: 8),
                _fallbackButton(
                  key: const ValueKey<String>('title-copy-use-description'),
                  label: 'Utiliser la description du projet',
                  selected: _promptFallback,
                  onPressed: () {
                    setState(() {
                      _promptFallback = true;
                      _prompt.clear();
                    });
                    _publish();
                  },
                ),
              ],
            ),
          ),
        ],
      );

  Widget _fallbackButton({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) => Align(
        alignment: Alignment.centerLeft,
        child: PokeMapButton(
          key: key,
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.secondary,
          isSelected: selected,
          leading: const Icon(Icons.refresh_rounded),
          onPressed: onPressed,
          child: Text(label),
        ),
      );

  void _synchronize() {
    _titleFallback = widget.profile?.title == null;
    _subtitleFallback = widget.profile?.subtitle == null;
    _promptFallback = widget.profile?.prompt == null;
    _replace(_title, widget.profile?.title ?? '');
    _replace(_subtitle, widget.profile?.subtitle ?? '');
    _replace(_prompt, widget.profile?.prompt ?? '');
  }

  void _replace(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  void _flushWhenFocusLeaves() {
    if (_focusNodes.every((node) => !node.hasFocus)) {
      _commit.flush();
    }
  }

  void _previewAndSchedule() {
    final profile = _currentProfile();
    widget.onPreviewChanged?.call(profile);
    final onChanged = widget.onChanged;
    _commit.schedule(() => onChanged(profile));
  }

  void _publish() {
    _commit.cancel();
    widget.onChanged(_currentProfile());
  }

  ProjectTitlePresentationProfile? _currentProfile() {
    final profile = (widget.profile ?? const ProjectTitlePresentationProfile())
        .copyWith(
          title: _titleFallback ? null : _title.text,
          subtitle: _subtitleFallback ? null : _subtitle.text,
          prompt: _promptFallback ? null : _prompt.text,
        );
    return profile == const ProjectTitlePresentationProfile() ? null : profile;
  }
}
