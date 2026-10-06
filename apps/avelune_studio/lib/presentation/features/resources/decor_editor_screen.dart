import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/decors/application/decor_source_support.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'atlas_selection_view.dart';
import 'decor_collision_mask.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';

part 'decor_editor_collision_section.dart';

class DecorEditorScreen extends StatefulWidget {
  const DecorEditorScreen({
    super.key,
    required this.draft,
    required this.visuals,
    required this.onSave,
    required this.onClose,
    required this.project,
  });
  final DecorDraft draft;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final Future<void> Function(ProjectElementEntry) onSave;
  final VoidCallback onClose;
  @override
  State<DecorEditorScreen> createState() => _DecorEditorScreenState();
}

enum _DecorSection { appearance, collisions, animation }

class _DecorEditorScreenState extends State<DecorEditorScreen> {
  late final name = TextEditingController(text: widget.draft.name);
  bool busy = false, fine = false, erase = false;
  int brushSize = 1;
  _DecorSection section = _DecorSection.appearance;
  String? error;
  DecorDraft get draft => widget.draft;
  void _change(VoidCallback edit) => setState(edit);

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      draft.name = name.text;
      await widget.onSave(draft.build());
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = draft.build(validateName: false);
    return Column(
      children: [
        StudioPageHeader(
          title: draft.original == null
              ? 'Préparer un décor'
              : 'Modifier le décor',
          description:
              'Choisissez son apparence, puis peignez ce qui bloque le passage.',
          actions: [
            StudioButton(
              label: 'Retour aux ressources',
              secondary: true,
              onPressed: busy ? null : widget.onClose,
            ),
            StudioButton(
              label: busy ? 'Enregistrement…' : 'Enregistrer le décor',
              icon: Icons.save_outlined,
              onPressed: busy ? null : save,
            ),
          ],
        ),
        if (error != null) StudioNotice(error!, isError: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _DecorSection.values)
                  StudioButton(
                    label: switch (entry) {
                      _DecorSection.appearance => 'Apparence',
                      _DecorSection.collisions => 'Collisions',
                      _DecorSection.animation => 'Animation',
                    },
                    secondary: section != entry,
                    onPressed: () => setState(() => section = entry),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 850 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              final editor = switch (section) {
                _DecorSection.appearance => appearance(result),
                _DecorSection.collisions => collisions(result),
                _DecorSection.animation => animation(result),
              };
              final information = metadata(result);
              if (compact) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (section != _DecorSection.collisions) ...[
                      information,
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      height: section == _DecorSection.collisions ? 580 : 440,
                      child: editor,
                    ),
                    if (section == _DecorSection.collisions) ...[
                      const SizedBox(height: 16),
                      information,
                    ],
                  ],
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: editor),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 290,
                      child: SingleChildScrollView(child: information),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget metadata(ProjectElementEntry result) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'Nom du décor'),
        onChanged: (value) => draft.name = value,
      ),
      const SizedBox(height: 12),
      Text(
        '${draft.selection.width} × ${draft.selection.height} cases · ${draft.tileset.name}',
      ),
      if (section != _DecorSection.collisions) ...[
        const SizedBox(height: 12),
        StudioAssetPreview(
          height: 180,
          child: widget.visuals.thumbnail(result, size: 150),
        ),
      ],
      if (draft.original != null) ...[
        const SizedBox(height: 12),
        const StudioNotice(
          'Définition partagée : enregistrer modifie toutes ses instances. Une variante conserve l’original.',
        ),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Créer une variante indépendante'),
          value: draft.variant,
          onChanged: busy
              ? null
              : (value) => setState(() => draft.variant = value!),
        ),
      ],
      if (section == _DecorSection.collisions) ...[
        const SizedBox(height: 16),
        const Text(
          'Rouge = passage bloqué. Peignez directement sur l’image ; la gomme retire uniquement la collision.',
        ),
        const SizedBox(height: 8),
        Text(
          draft.hasFineCollision
              ? 'Masque au pixel · pixels rouges bloquants'
              : '${draft.blocked.length} cases concernées',
        ),
        const SizedBox(height: 16),
        const Text(
          'L’occlusion et les animations restent indépendantes. Les changements sont enregistrés avec le décor.',
        ),
        const SizedBox(height: 16),
        StudioButton(
          label: 'Effacer toutes les collisions',
          icon: Icons.layers_clear_outlined,
          variant: StudioButtonVariant.destructive,
          onPressed: busy
              ? null
              : () => setState(() => draft.setBlocked(false)),
        ),
      ],
    ],
  );

  Widget appearance(ProjectElementEntry result) {
    final source = draft.tileset.source;
    final visuals = widget.visuals;
    final editable =
        source is ProjectRegularAtlasTilesetSource &&
        canCreateDecor(draft.tileset, widget.project) &&
        visuals is ResourceWorkspaceVisuals &&
        (draft.original == null || draft.original!.frames.length == 1);
    if (!editable) {
      return Column(
        children: [
          const StudioNotice(
            'Cette source ou animation reste utilisable. Son découpage avancé est conservé et ne peut pas être redéfini ici.',
          ),
          Expanded(
            child: StudioAssetPreview(
              child: visuals.thumbnail(result, size: 320),
            ),
          ),
        ],
      );
    }
    return AtlasSelectionView(
      source: source,
      selected: draft.selection,
      image: (visuals as ResourceWorkspaceVisuals).atlasPreview(
        draft.tileset.id,
      ),
      onSelected: (rect) => setState(() {
        if (result.collisionProfile?.collisionMask != null &&
            (rect.width != draft.selection.width ||
                rect.height != draft.selection.height)) {
          error =
              'Conservez les dimensions de ce décor pour garder son masque fin. Effacez explicitement toutes les collisions avant de changer sa taille.';
          return;
        }
        error = null;
        draft.selection = rect;
        if (!draft.hasFineCollision) {
          draft.blocked.removeWhere(
            (cell) => cell.x >= rect.width || cell.y >= rect.height,
          );
        }
      }),
    );
  }

  Widget animation(ProjectElementEntry result) => ListView(
    children: [
      const StudioNotice(
        'Les images et durées existantes sont conservées. Les déclencheurs de chaque exemplaire se règlent dans la Carte.',
      ),
      const SizedBox(height: 12),
      for (var index = 0; index < result.frames.length; index++)
        ListTile(
          leading: widget.visuals.thumbnail(
            result.copyWith(frames: [result.frames[index]]),
          ),
          title: Text('Image ${index + 1}'),
          subtitle: Text(
            result.frames[index].durationMs == null
                ? 'Durée par défaut'
                : '${result.frames[index].durationMs} ms',
          ),
        ),
    ],
  );
}
