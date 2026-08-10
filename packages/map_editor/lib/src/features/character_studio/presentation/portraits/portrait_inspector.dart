import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_portrait_inspector_read_model.dart';
import '../../application/character_studio_media_resolver.dart';

typedef PortraitInspectorReplaceCallback = Future<bool> Function();
typedef PortraitInspectorFitCallback =
    Future<bool> Function(CharacterPortraitFitMode fitMode);

class PortraitInspector extends StatefulWidget {
  const PortraitInspector({
    super.key,
    required this.project,
    required this.character,
    required this.portraitStateId,
    required this.projectRootPath,
    required this.projectRevision,
    required this.mediaResolver,
    required this.isSaving,
    required this.onReplace,
    required this.onFitChanged,
    this.dialogueSourceReader =
        const FileCharacterPortraitDialogueSourceReader(),
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final String portraitStateId;
  final String projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract mediaResolver;
  final CharacterPortraitDialogueSourceReader dialogueSourceReader;
  final bool isSaving;
  final PortraitInspectorReplaceCallback onReplace;
  final PortraitInspectorFitCallback onFitChanged;

  @override
  State<PortraitInspector> createState() => _PortraitInspectorState();
}

class _PortraitInspectorState extends State<PortraitInspector> {
  late Future<CharacterPortraitInspectorReadModel> _model;
  bool _busy = false;

  bool get _locked => widget.isSaving || _busy;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant PortraitInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project ||
        oldWidget.character != widget.character ||
        oldWidget.portraitStateId != widget.portraitStateId ||
        oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.projectRevision != widget.projectRevision ||
        oldWidget.mediaResolver != widget.mediaResolver ||
        oldWidget.dialogueSourceReader != widget.dialogueSourceReader) {
      _reload();
    }
  }

  void _reload() {
    _model =
        CharacterPortraitInspectorReadModelLoader(
          mediaResolver: widget.mediaResolver,
          dialogueSourceReader: widget.dialogueSourceReader,
        ).load(
          project: widget.project,
          character: widget.character,
          portraitStateId: widget.portraitStateId,
          projectRootPath: widget.projectRootPath,
          projectRevision: widget.projectRevision,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CharacterPortraitInspectorReadModel>(
      future: _model,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(14),
            child: PokeMapEmptyState(
              title: 'Inspecteur indisponible',
              description:
                  'L’expression sélectionnée ne peut pas être inspectée.',
              icon: Icon(CupertinoIcons.exclamationmark_triangle),
              compact: true,
            ),
          );
        }
        final model = snapshot.data;
        if (model == null) {
          return Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.pokeMapColors.brandPrimary,
              ),
            ),
          );
        }
        return _buildInspector(context, model);
      },
    );
  }

  Widget _buildInspector(
    BuildContext context,
    CharacterPortraitInspectorReadModel model,
  ) {
    final portrait = model.portrait;
    return SingleChildScrollView(
      key: ValueKey<String>('portrait-inspector-${model.definition.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Inspecteur du portrait',
            description:
                '${widget.character.name} · ${model.definition.displayName}',
          ),
          const SizedBox(height: 10),
          PokeMapPanel(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InspectorField(
                  label: 'État sélectionné',
                  value: model.definition.displayName,
                ),
                const SizedBox(height: 10),
                _InspectorField(
                  label: 'Clé du projet',
                  value: model.definition.id,
                  icon: CupertinoIcons.lock_fill,
                ),
                const SizedBox(height: 10),
                _InspectorField(
                  label: 'Source',
                  value: portrait?.assetId ?? 'Aucune source',
                  icon: CupertinoIcons.doc_fill,
                ),
                const SizedBox(height: 10),
                PokeMapButton(
                  key: ValueKey<String>(
                    portrait == null
                        ? 'portrait-inspector-add-${model.definition.id}'
                        : 'portrait-inspector-replace-${model.definition.id}',
                  ),
                  onPressed: _locked ? null : _replace,
                  isLoading: _busy,
                  leading: Icon(
                    portrait == null
                        ? CupertinoIcons.add
                        : CupertinoIcons.arrow_2_circlepath,
                  ),
                  child: Text(
                    portrait == null ? 'Ajouter un portrait' : 'Remplacer',
                  ),
                ),
                const SizedBox(height: 10),
                PokeMapDropdownField<CharacterPortraitFitMode>(
                  key: const ValueKey<String>('portrait-inspector-fit'),
                  label: 'Mode de cadrage',
                  value: portrait?.fitMode ?? CharacterPortraitFitMode.contain,
                  items: const <PokeMapDropdownItem<CharacterPortraitFitMode>>[
                    PokeMapDropdownItem<CharacterPortraitFitMode>(
                      value: CharacterPortraitFitMode.contain,
                      label: 'Ajuster dans le cadre',
                    ),
                    PokeMapDropdownItem<CharacterPortraitFitMode>(
                      value: CharacterPortraitFitMode.cover,
                      label: 'Remplir le cadre',
                    ),
                  ],
                  enabled: portrait != null && !_locked,
                  onChanged: _setFit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PokeMapSectionHeader(title: 'Aperçu en dialogue'),
          const SizedBox(height: 7),
          _DialoguePreview(model: model, widget: widget),
          const SizedBox(height: 12),
          const PokeMapSectionHeader(title: 'Validation'),
          const SizedBox(height: 7),
          _SourceDiagnostic(status: model.sourceStatus),
          const SizedBox(height: 7),
          PokeMapDiagnosticCallout(
            severity: model.usages.isEmpty
                ? PokeMapDiagnosticSeverity.info
                : PokeMapDiagnosticSeverity.info,
            title: model.usages.isEmpty
                ? 'Aucune référence'
                : 'Référence utilisée',
            message: _usageLabel(model.dialogueCount),
          ),
          const SizedBox(height: 7),
          PokeMapDiagnosticCallout(
            severity: model.missingCharacterNames.isEmpty
                ? PokeMapDiagnosticSeverity.info
                : PokeMapDiagnosticSeverity.warning,
            title: model.missingCharacterNames.isEmpty
                ? 'Couverture complète'
                : 'Couverture incomplète',
            message: model.missingCharacterNames.isEmpty
                ? 'Tous les personnages possèdent ce portrait.'
                : 'Manquant pour ${model.missingCharacterNames.length} '
                      '${model.missingCharacterNames.length == 1 ? 'personnage' : 'personnages'} : '
                      ' ${model.missingCharacterNames.join(', ')}',
          ),
        ],
      ),
    );
  }

  Future<void> _replace() async {
    setState(() => _busy = true);
    try {
      await widget.onReplace();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setFit(CharacterPortraitFitMode fitMode) async {
    setState(() => _busy = true);
    try {
      await widget.onFitChanged(fitMode);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _InspectorField extends StatelessWidget {
  const _InspectorField({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.pokeMapColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.pokeMapColors.textMuted, size: 13),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DialoguePreview extends StatelessWidget {
  const _DialoguePreview({required this.model, required this.widget});

  final CharacterPortraitInspectorReadModel model;
  final PortraitInspector widget;

  @override
  Widget build(BuildContext context) {
    final portrait = model.portrait;
    final request = portrait == null
        ? null
        : CharacterStudioMediaRequest(
            projectRootPath: widget.projectRootPath,
            assetId: portrait.assetId,
            projectRevision: widget.projectRevision,
          );
    return PokeMapPanel(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox.square(
            dimension: 72,
            child: _DialoguePortrait(
              resolver: widget.mediaResolver,
              request: request,
              fit: portrait?.fitMode == CharacterPortraitFitMode.cover
                  ? BoxFit.cover
                  : BoxFit.contain,
              label: model.definition.displayName,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PokeMapPanel(
              padding: const EdgeInsets.all(10),
              borderRadius: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.character.name,
                    style: TextStyle(
                      color: context.pokeMapColors.brandPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.previewText,
                    style: TextStyle(
                      color: context.pokeMapColors.textPrimary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialoguePortrait extends StatelessWidget {
  const _DialoguePortrait({
    required this.resolver,
    required this.request,
    required this.fit,
    required this.label,
  });

  final CharacterStudioMediaResolverContract resolver;
  final CharacterStudioMediaRequest? request;
  final BoxFit fit;
  final String label;

  @override
  Widget build(BuildContext context) {
    final currentRequest = request;
    return PokeMapMediaPreviewSurface(
      semanticLabel: 'Portrait $label dans le dialogue',
      child: currentRequest == null
          ? Center(
              child: Icon(
                CupertinoIcons.person_crop_circle_badge_xmark,
                color: context.pokeMapColors.textDisabled,
                size: 28,
              ),
            )
          : FutureBuilder<Uint8List>(
              future: resolver.resolve(currentRequest),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return Center(
                    child: Icon(
                      snapshot.hasError
                          ? CupertinoIcons.exclamationmark_triangle
                          : CupertinoIcons.ellipsis,
                      color: snapshot.hasError
                          ? context.pokeMapColors.warning
                          : context.pokeMapColors.textMuted,
                      size: 24,
                    ),
                  );
                }
                return Image.memory(
                  bytes,
                  fit: fit,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, _, _) => Center(
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: context.pokeMapColors.warning,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SourceDiagnostic extends StatelessWidget {
  const _SourceDiagnostic({required this.status});

  final CharacterPortraitSourceStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      CharacterPortraitSourceStatus.valid => const PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Source valide',
        message: 'Le PNG portable est disponible et lisible.',
      ),
      CharacterPortraitSourceStatus.missingPortrait =>
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.warning,
          title: 'Portrait absent',
          message: 'Aucune image n’est affectée à cette expression.',
        ),
      CharacterPortraitSourceStatus.invalidSource =>
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error,
          title: 'Source invalide',
          message: 'L’asset est absent, illisible ou n’est pas un PNG valide.',
        ),
    };
  }
}

String _usageLabel(int count) {
  if (count == 0) return 'Utilisé dans 0 dialogue';
  if (count == 1) return 'Utilisé dans 1 dialogue';
  return 'Utilisé dans $count dialogues';
}
