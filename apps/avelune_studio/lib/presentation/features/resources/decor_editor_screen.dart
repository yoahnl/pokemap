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

class _DecorEditorScreenState extends State<DecorEditorScreen> {
  late final name = TextEditingController(text: widget.draft.name);
  bool busy = false;
  String? error;
  DecorDraft get draft => widget.draft;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
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
    final source = draft.tileset.source;
    final visuals = widget.visuals;
    final editable =
        source is ProjectRegularAtlasTilesetSource &&
        canCreateDecor(draft.tileset, widget.project) &&
        visuals is ResourceWorkspaceVisuals &&
        (draft.original == null || draft.original!.frames.length == 1);
    final result = draft.build(validateName: false);
    return Column(
      children: [
        StudioPageHeader(
          title: draft.original == null
              ? 'Préparer un décor'
              : 'Modifier la définition',
          description:
              'Sélectionnez l’apparence et préparez son utilisation sur la carte.',
          actions: [
            StudioButton(
              label: 'Retour aux ressources',
              secondary: true,
              onPressed: busy ? null : widget.onClose,
            ),
            StudioButton(
              label: busy ? 'Enregistrement…' : 'Enregistrer et utiliser',
              onPressed: busy ? null : save,
            ),
          ],
        ),
        if (error != null) StudioNotice(error!, isError: true),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final preview = SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nom du décor',
                      ),
                      onChanged: (v) => draft.name = v,
                    ),
                    const SizedBox(height: 16),
                    StudioAssetPreview(
                      height: 180,
                      child: visuals.thumbnail(result, size: 150),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${draft.selection.width} × ${draft.selection.height} cases',
                    ),
                    if (draft.original != null) ...[
                      const SizedBox(height: 12),
                      const StudioNotice(
                        'Définition partagée : enregistrer modifie toutes ses instances. Une variante laisse les instances originales intactes.',
                      ),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Créer une variante indépendante'),
                        value: draft.variant,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => draft.variant = v!),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Collisions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StudioButton(
                          label: 'Traversable',
                          secondary: true,
                          onPressed: () =>
                              setState(() => draft.setBlocked(false)),
                        ),
                        StudioButton(
                          label: 'Bloquer',
                          secondary: true,
                          onPressed: () =>
                              setState(() => draft.setBlocked(true)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cliquez les cases pour peindre le masque. L’occlusion reste indépendante.',
                    ),
                    const SizedBox(height: 8),
                    DecorCollisionMask(
                      width: draft.selection.width,
                      height: draft.selection.height,
                      blocked: draft.collisionChanged
                          ? draft.blocked
                          : {...?draft.original?.collisionProfile?.cells},
                      onToggle: (point) {
                        if (!draft.collisionChanged) {
                          draft.blocked = {
                            ...?draft.original?.collisionProfile?.cells,
                          };
                          draft.collisionChanged = true;
                        }
                        setState(
                          () => draft.blocked.contains(point)
                              ? draft.blocked.remove(point)
                              : draft.blocked.add(point),
                        );
                      },
                    ),
                  ],
                ),
              );
              final sourceView = editable
                  ? AtlasSelectionView(
                      source: source,
                      selected: draft.selection,
                      image: (visuals as ResourceWorkspaceVisuals).atlasPreview(
                        draft.tileset.id,
                      ),
                      onSelected: (r) => setState(() {
                        draft.selection = r;
                        if (draft.collisionChanged) {
                          draft.blocked.removeWhere(
                            (p) => p.x >= r.width || p.y >= r.height,
                          );
                        }
                      }),
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: StudioNotice(
                          'Cette source ou animation reste utilisable. Sa conversion rectangulaire n’est pas encore éditable dans Studio ; les données avancées sont conservées.',
                        ),
                      ),
                    );
              if (c.maxWidth < 720) {
                return ListView(
                  children: [
                    SizedBox(height: 300, child: sourceView),
                    SizedBox(height: 470, child: preview),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: sourceView),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 310, child: preview),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
