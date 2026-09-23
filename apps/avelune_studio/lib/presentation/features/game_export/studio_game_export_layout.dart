part of 'studio_game_export_page.dart';

extension _StudioGameExportLayout on _StudioGameExportPageState {
  Widget _layout(BuildContext context, BoxConstraints bounds) {
    final wide =
        bounds.maxWidth >= 1050 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.25;
    final sideWidth = (bounds.maxWidth * .32).clamp(300.0, 390.0);
    final formWidth = wide
        ? bounds.maxWidth - sideWidth - 52
        : bounds.maxWidth - 32;
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Row(
            children: [
              const StudioIconTile(
                icon: Icons.inventory_2_outlined,
                tone: StudioTone.info,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exporter le jeu',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${controller.projectName} · Créez un paquet .avelunegame pour Avelune Player.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: wide
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const ValueKey('export-form-scroll'),
                          child: _form(formWidth),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: sideWidth,
                        child: SingleChildScrollView(
                          key: const ValueKey('export-summary-scroll'),
                          child: _summary(),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  key: const ValueKey('export-page-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _form(formWidth),
                      const SizedBox(height: 12),
                      _summary(),
                    ],
                  ),
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                if (controller.canCancel)
                  StudioButton(
                    label: 'Annuler l’export',
                    secondary: true,
                    onPressed: controller.cancel,
                  )
                else if (widget.onBack != null)
                  StudioButton(
                    label: 'Retour à l’accueil',
                    secondary: true,
                    onPressed: controller.operationActive
                        ? null
                        : widget.onBack,
                  ),
                StudioButton(
                  key: const ValueKey('start-game-export'),
                  label: widget.hasPendingChanges()
                      ? 'Enregistrer puis exporter'
                      : controller.outputPath == null
                      ? 'Exporter le jeu'
                      : 'Exporter à nouveau',
                  icon: Icons.archive_outlined,
                  onPressed:
                      !_loaded || !controller.canStart || _selectingDestination
                      ? null
                      : _export,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
