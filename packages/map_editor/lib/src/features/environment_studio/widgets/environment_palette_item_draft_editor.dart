import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/shared/cupertino_editor_widgets.dart';
import '../authoring/environment_preset_draft.dart';

/// Carte éditable d’un [EnvironmentPaletteItemDraft] (Lot Environment-14).
///
/// [ValueKey] côté parent : **`palette-draft-slot-$index`** ([index] stable dans
/// la liste). Quand un item est retiré, les indices se réindexent : les
/// contrôleurs du slot `i` sont resynchronisés depuis le nouvel [item] via
/// [didUpdateWidget] pour éviter d’afficher le texte d’un ancien voisin.
class EnvironmentPaletteItemDraftEditor extends StatefulWidget {
  const EnvironmentPaletteItemDraftEditor({
    super.key,
    required this.index,
    required this.item,
    required this.projectElements,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final EnvironmentPaletteItemDraft item;

  /// Éléments du manifeste (`ProjectManifest.elements`) pour le picker.
  final List<ProjectElementEntry> projectElements;

  final ValueChanged<EnvironmentPaletteItemDraft> onChanged;
  final VoidCallback onRemove;

  @override
  State<EnvironmentPaletteItemDraftEditor> createState() =>
      _EnvironmentPaletteItemDraftEditorState();
}

class _EnvironmentPaletteItemDraftEditorState
    extends State<EnvironmentPaletteItemDraftEditor> {
  late final TextEditingController _elementIdCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _tagsCtrl;

  @override
  void initState() {
    super.initState();
    _elementIdCtrl = TextEditingController(text: widget.item.elementId);
    _weightCtrl = TextEditingController(text: widget.item.weight.toString());
    _tagsCtrl = TextEditingController(text: _tagsToField(widget.item.tags));
  }

  @override
  void didUpdateWidget(covariant EnvironmentPaletteItemDraftEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _elementIdCtrl.text = widget.item.elementId;
      _weightCtrl.text = widget.item.weight.toString();
      _tagsCtrl.text = _tagsToField(widget.item.tags);
    }
  }

  @override
  void dispose() {
    _elementIdCtrl.dispose();
    _weightCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  static String _tagsToField(Set<String> tags) {
    final list = tags.toList()..sort();
    return list.join(', ');
  }

  static Set<String> _fieldToTags(String text) {
    return text.split(',').map((t) => t.trim()).toSet();
  }

  static int _collisionToSegment(EnvironmentCollisionMode m) {
    return switch (m) {
      EnvironmentCollisionMode.useElementDefault => 0,
      EnvironmentCollisionMode.forceEnabled => 1,
      EnvironmentCollisionMode.forceDisabled => 2,
    };
  }

  static EnvironmentCollisionMode _segmentToCollision(int i) {
    return switch (i) {
      1 => EnvironmentCollisionMode.forceEnabled,
      2 => EnvironmentCollisionMode.forceDisabled,
      _ => EnvironmentCollisionMode.useElementDefault,
    };
  }

  void _emit({
    String? elementId,
    int? weight,
    EnvironmentCollisionMode? collisionMode,
    Set<String>? tags,
  }) {
    widget.onChanged(
      widget.item.copyWith(
        elementId: elementId,
        weight: weight,
        collisionMode: collisionMode,
        tags: tags,
      ),
    );
  }

  Future<void> _pickElementFromLibrary(BuildContext context) async {
    final sorted = [...widget.projectElements]
      ..sort((a, b) => a.id.compareTo(b.id));
    if (sorted.isEmpty) {
      return;
    }
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: const Text('Éléments du projet'),
          message: const Text(
            'Sélectionnez un élément de la bibliothèque du projet.',
          ),
          actions: [
            for (final e in sorted)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, e.id),
                child: Text(
                  '${e.id} — ${e.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
        );
      },
    );
    if (!context.mounted) {
      return;
    }
    if (choice != null && choice.isNotEmpty) {
      _elementIdCtrl.text = choice;
      _emit(elementId: choice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final fill = EditorChrome.chipFill(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    final seg = _collisionToSegment(widget.item.collisionMode);

    return DecoratedBox(
      key: Key('environment-studio-palette-draft-item-${widget.index}'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        color: fill,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${widget.index + 1}',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: Key(
                    'environment-studio-palette-draft-remove-${widget.index}',
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  onPressed: widget.onRemove,
                  child: const Text('Retirer'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Element id',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (widget.projectElements.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  key: Key(
                    'environment-studio-palette-draft-pick-element-${widget.index}',
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  onPressed: () => _pickElementFromLibrary(context),
                  child: const Text('Choisir dans la bibliothèque du projet'),
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              Text(
                'Aucun élément dans le manifeste — saisie manuelle uniquement.',
                style: TextStyle(color: subtle, fontSize: 11.5, height: 1.3),
              ),
              const SizedBox(height: 6),
            ],
            CupertinoTextField(
              key: Key(
                'environment-studio-palette-draft-element-${widget.index}',
              ),
              controller: _elementIdCtrl,
              placeholder: 'Identifiant d’élément (saisie manuelle possible)',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: (v) => _emit(elementId: v),
            ),
            const SizedBox(height: 10),
            Text(
              'Poids',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: Key(
                'environment-studio-palette-draft-weight-${widget.index}',
              ),
              controller: _weightCtrl,
              placeholder: '1',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: (raw) {
                final t = raw.trim();
                if (t.isEmpty) {
                  return;
                }
                final parsed = int.tryParse(t);
                if (parsed == null) {
                  return;
                }
                _emit(weight: parsed);
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Collision',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                key: Key(
                  'environment-studio-palette-draft-collision-${widget.index}',
                ),
                groupValue: seg,
                children: {
                  0: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Défaut élément',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: label),
                    ),
                  ),
                  1: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Collision forcée',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: label),
                    ),
                  ),
                  2: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Collision désactivée',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: label),
                    ),
                  ),
                },
                onValueChanged: (v) {
                  if (v == null) {
                    return;
                  }
                  _emit(collisionMode: _segmentToCollision(v));
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tags',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            CupertinoTextField(
              key: Key(
                'environment-studio-palette-draft-tags-${widget.index}',
              ),
              controller: _tagsCtrl,
              placeholder: 'tree, canopy',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onChanged: (v) => _emit(tags: _fieldToTags(v)),
            ),
          ],
        ),
      ),
    );
  }
}
