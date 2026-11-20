part of 'scene_focus_workspace.dart';

extension _SceneFocusToolbar on _SceneFocusWorkspaceState {
  Widget _graphToolbar(BuildContext context, _SceneDialoguePreview dialogues) {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StudioSpacing.l,
            vertical: StudioSpacing.xs,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: StudioSpacing.l,
                runSpacing: StudioSpacing.s,
                children: [
                  Wrap(
                    spacing: StudioSpacing.m,
                    runSpacing: StudioSpacing.xs,
                    children: [
                      StudioButton(
                        key: const ValueKey('scene-graph-open-palette'),
                        label: l10n.sceneGraphSearch,
                        icon: Icons.add,
                        variant: StudioButtonVariant.quiet,
                        onPressed: _editable ? () => _setPalette(true) : null,
                      ),
                      StudioButton(
                        key: const ValueKey('scene-graph-show-all'),
                        label: l10n.sceneGraphFit,
                        icon: Icons.fit_screen,
                        variant: StudioButtonVariant.quiet,
                        onPressed: () => _canvas.currentState
                          ?..showAll()
                          ..requestFocus(),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: StudioSpacing.s,
                    runSpacing: StudioSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (dialogues.options.length > 1)
                        SizedBox(
                          width: 160,
                          child: StudioSelect(
                            key: const ValueKey('scene-graph-preview-language'),
                            label: l10n.dialogueCatalogPreviewLanguage,
                            value: dialogues.language,
                            options: dialogues.options,
                            onChanged: _selectPreviewLanguage,
                            compact: true,
                          ),
                        ),
                      if (dialogues.fallbackLocales.isNotEmpty)
                        StudioBadge(
                          l10n.dialogueCatalogFallback(
                            dialogues.fallbackLocales.join(', ').toUpperCase(),
                          ),
                          tone: StudioTone.warning,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
