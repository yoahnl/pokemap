part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// This local sub-library keeps the "placed instances" UI together.
// The panel shell still resolves the active scope and delegates rendering here.

class _PlacedElementInstancesScope {
  const _PlacedElementInstancesScope({
    required this.layerId,
    required this.layerName,
    required this.instances,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String? layerId;
  final String? layerName;
  final List<_PlacedElementInstanceVm> instances;
  final String emptyTitle;
  final String emptyMessage;
}

class _PlacedElementInstanceVm {
  const _PlacedElementInstanceVm({
    required this.instance,
    required this.element,
    required this.layerName,
    required this.occurrence,
    required this.previewAvailable,
  });

  final MapPlacedElement instance;
  final ProjectElementEntry? element;
  final String layerName;
  final int occurrence;
  final bool previewAvailable;

  String get displayLabel =>
      '${element?.id ?? instance.elementId} #$occurrence';
  GridPos get pos => instance.pos;
  String get layerId => instance.layerId;
  String get instanceId => instance.id;
  bool get applyCollision => instance.applyCollision;
  double get opacity => instance.opacity;
  MapPlacedElementAnimation? get animation => instance.animation;
  List<MapPlacedElementBehavior> get behaviors => instance.behaviors;
  MapPlacedElementShadowOverride? get shadowOverride => instance.shadowOverride;
  int get frameCount => element?.frames.length ?? 1;
  TilesetSourceRect get source =>
      element?.frames.primarySource ??
      const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1);
}

class _PlacedInstancesSection extends StatelessWidget {
  const _PlacedInstancesSection({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.scope,
    required this.selectedInstanceId,
    required this.selectedInstance,
    required this.onSelectInstance,
  });

  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final _PlacedElementInstancesScope scope;
  final String? selectedInstanceId;
  final _PlacedElementInstanceVm? selectedInstance;
  final ValueChanged<_PlacedElementInstanceVm?> onSelectInstance;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCyan;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final separator = CupertinoColors.separator.resolveFrom(context);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: context.pokeMapColors.surfaceBase,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.pokeMapColors.borderSubtle),
            boxShadow: EditorChrome.sectionCardShadows(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.square_stack_3d_down_right_fill,
                    size: 15,
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instances posées (calque actif)',
                      style: TextStyle(
                        color: label,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${scope.instances.length}',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                scope.layerId == null
                    ? 'Calque actif: —'
                    : 'Calque actif: ${scope.layerName ?? scope.layerId}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              if (scope.instances.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EditorChrome.largeIslandSurfaceColor(
                      context,
                      tint: Colors.white.withValues(alpha: 0.02),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: separator),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scope.emptyTitle,
                        style: TextStyle(
                          color: label,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        scope.emptyMessage,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height:
                      math.min(260, scope.instances.length * 67 + 6).toDouble(),
                  child: ListView.separated(
                    itemCount: scope.instances.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final instance = scope.instances[index];
                      return _PlacedInstanceCard(
                        image: image,
                        tileWidth: tileWidth,
                        tileHeight: tileHeight,
                        instance: instance,
                        selected: selectedInstanceId == instance.instanceId,
                        onTap: () => onSelectInstance(instance),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        PlacedElementPropertiesPanel(
          instanceId: selectedInstance?.instanceId,
          previewImage: image,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          previewAvailable: selectedInstance?.previewAvailable ?? false,
        ),
      ],
    );
  }
}

class PlacedElementPropertiesPanel extends ConsumerWidget {
  const PlacedElementPropertiesPanel({
    super.key,
    required this.instanceId,
    this.previewImage,
    this.tileWidth,
    this.tileHeight,
    this.previewAvailable = false,
    this.scrollable = false,
  });

  final String? instanceId;

  /// A borrowed image owned by the caller. This panel never loads or disposes
  /// project images, so the palette remains the single cache-lease owner.
  final ui.Image? previewImage;
  final int? tileWidth;
  final int? tileHeight;
  final bool previewAvailable;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          project: state.project,
          map: state.activeMap,
          projectRootPath: state.projectRootPath,
        ),
      ),
    );
    final selected = _resolvePlacedElementInstance(
      project: snapshot.project,
      map: snapshot.map,
      instanceId: instanceId,
      previewAvailable: previewAvailable && previewImage != null,
    );
    final notifier = ref.read(editorNotifierProvider.notifier);
    final colors = context.pokeMapColors;
    final secondary = colors.textSecondary;
    final label = colors.textPrimary;
    final formKey = ValueKey<String>(
      'placed-element-properties-form-${selected?.instanceId ?? instanceId ?? 'none'}',
    );

    final content = KeyedSubtree(
      key: formKey,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: colors.surfaceBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 15,
                  color: EditorChrome.inspectorJoyMint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Propriétés de l'instance sélectionnée",
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (selected == null)
              Text(
                instanceId == null
                    ? 'Sélectionne une instance dans la liste pour afficher ses détails.'
                    : 'Instance introuvable',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              )
            else ...[
              _PropertyLine(
                label: 'Élément source',
                value: selected.element == null
                    ? 'Introuvable (${selected.instance.elementId})'
                    : '${selected.element!.name} (${selected.element!.id})',
              ),
              _PropertyLine(
                label: 'Instance',
                value: selected.displayLabel,
              ),
              _PropertyLine(
                label: 'Position',
                value: '(${selected.pos.x}, ${selected.pos.y})',
              ),
              _PropertyLine(
                label: 'Taille',
                value: '${selected.source.width} x ${selected.source.height}',
              ),
              _PropertyLine(
                label: 'Layer',
                value: '${selected.layerName} (${selected.layerId})',
              ),
              _PropertyLine(
                label: 'ID interne',
                value: selected.instanceId,
              ),
              const SizedBox(height: 8),
              _CollisionToggleRow(
                value: selected.applyCollision,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  notifier.setPlacedElementInstanceCollisionApplied(
                    instanceId: selected.instanceId,
                    applyCollision: value,
                  );
                },
              ),
              const SizedBox(height: 8),
              _OpacitySliderRow(
                value: selected.opacity,
                onChangeStart: notifier.beginMapStroke,
                onChanged: (value) => notifier.setPlacedElementInstanceOpacity(
                  instanceId: selected.instanceId,
                  opacity: value,
                  partOfStroke: true,
                ),
                onChangeEnd: notifier.endMapStroke,
              ),
              const SizedBox(height: 8),
              PlacedElementShadowOverrideSection(
                manifest: snapshot.project!,
                element: selected.element,
                instance: selected.instance,
                shadowOverride: selected.shadowOverride,
                onChanged: (next) =>
                    notifier.setPlacedElementInstanceShadowOverride(
                  instanceId: selected.instanceId,
                  shadowOverride: next,
                ),
                onEnsureDefaultShadowProfiles:
                    notifier.ensureDefaultShadowProfiles,
              ),
              const SizedBox(height: 8),
              _PlacedElementAnimationSection(
                value: selected.animation,
                frameCount: selected.frameCount,
                previewEnabled: selected.previewAvailable,
                image: previewImage,
                sourceFrames: selected.element?.frames ?? const [],
                tileWidth: tileWidth ?? snapshot.project!.settings.tileWidth,
                tileHeight: tileHeight ?? snapshot.project!.settings.tileHeight,
                onChanged: (next) =>
                    notifier.setPlacedElementInstanceAnimationConfig(
                  instanceId: selected.instanceId,
                  animation: next,
                ),
              ),
              const SizedBox(height: 8),
              _PlacedElementBehaviorsSection(
                value: selected.behaviors,
                dialogues: snapshot.project!.dialogues,
                projectRootPath: snapshot.projectRootPath,
                onChanged: (next) => notifier.setPlacedElementInstanceBehaviors(
                  instanceId: selected.instanceId,
                  behaviors: next,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                color: CupertinoColors.systemRed.withValues(alpha: 0.9),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onPressed: () => _showDeletePlacedInstanceDialog(
                  context,
                  notifier: notifier,
                  mapIdentity: snapshot.map!,
                  instance: selected,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.trash, size: 14),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Supprimer cette instance',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!scrollable) {
      return content;
    }
    return SingleChildScrollView(
      primary: false,
      child: content,
    );
  }
}

_PlacedElementInstanceVm? _resolvePlacedElementInstance({
  required ProjectManifest? project,
  required MapData? map,
  required String? instanceId,
  required bool previewAvailable,
}) {
  if (project == null || map == null || instanceId == null) {
    return null;
  }

  MapPlacedElement? selected;
  for (final instance in map.placedElements) {
    if (instance.id == instanceId) {
      selected = instance;
      break;
    }
  }
  if (selected == null) {
    return null;
  }
  final selectedLayerId = selected.layerId;

  MapLayer? layer;
  for (final candidate in map.layers) {
    if (candidate.id == selectedLayerId) {
      layer = candidate;
      break;
    }
  }
  final sameLayerInstances = map.placedElements
      .where((instance) => instance.layerId == selectedLayerId)
      .toList(growable: false)
    ..sort((a, b) {
      final yCompare = a.pos.y.compareTo(b.pos.y);
      if (yCompare != 0) return yCompare;
      final xCompare = a.pos.x.compareTo(b.pos.x);
      if (xCompare != 0) return xCompare;
      return a.id.compareTo(b.id);
    });
  var occurrence = 0;
  for (final instance in sameLayerInstances) {
    if (instance.elementId == selected.elementId) {
      occurrence += 1;
    }
    if (instance.id == selected.id) {
      break;
    }
  }

  ProjectElementEntry? element;
  for (final entry in project.elements) {
    if (entry.id == selected.elementId) {
      element = entry;
      break;
    }
  }
  return _PlacedElementInstanceVm(
    instance: selected,
    element: element,
    layerName: layer?.name ?? selected.layerId,
    occurrence: occurrence,
    previewAvailable: previewAvailable,
  );
}

Future<void> _showDeletePlacedInstanceDialog(
  BuildContext context, {
  required EditorNotifier notifier,
  required MapData mapIdentity,
  required _PlacedElementInstanceVm instance,
}) async {
  final elementName = instance.element?.name ?? instance.instance.elementId;
  final shouldDelete = await showMacosEditorTwoChoiceAlert(
    context,
    title: 'Supprimer l’instance',
    message:
        'Supprimer "$elementName" en (${instance.pos.x}, ${instance.pos.y}) sur "${instance.layerName}" ?',
    primaryLabel: 'Supprimer',
    primaryIsDestructive: true,
  );
  if (!shouldDelete) {
    return;
  }
  notifier.deletePlacedElementInstance(
    instanceId: instance.instanceId,
    expectedMapIdentity: mapIdentity,
    expectedInstanceIdentity: instance.instance,
  );
}

class _PlacedInstanceCard extends StatelessWidget {
  const _PlacedInstanceCard({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.instance,
    required this.selected,
    required this.onTap,
  });

  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final _PlacedElementInstanceVm instance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCyan;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final border = CupertinoColors.separator.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.13)
              : EditorPaintColors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? accent : border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                ),
                child: instance.element == null
                    ? Icon(
                        CupertinoIcons.question_circle,
                        size: 18,
                        color: secondary,
                      )
                    : !instance.previewAvailable
                        ? Icon(
                            CupertinoIcons.question_circle,
                            size: 18,
                            color: secondary,
                          )
                        : _PaletteRectPreview(
                            image: image,
                            source: instance.source,
                            tileWidth: tileWidth,
                            tileHeight: tileHeight,
                          ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    instance.element?.name ?? 'Élément introuvable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    instance.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Pos: (${instance.pos.x}, ${instance.pos.y}) · Layer: ${instance.layerName} · Collision: ${instance.applyCollision ? 'on' : 'off'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (selected)
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 16,
                color: EditorChrome.inspectorJoyCyan,
              ),
          ],
        ),
      ),
    );
  }
}

class _PropertyLine extends StatelessWidget {
  const _PropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final primary = CupertinoColors.label.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: secondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: primary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollisionToggleRow extends StatelessWidget {
  const _CollisionToggleRow({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final colors = context.pokeMapColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collision',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Appliquer la collision de l’élément',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: CupertinoSwitch(
              key: const ValueKey('placed-element-collision-switch'),
              value: value,
              onChanged: (next) => onChanged(next),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpacitySliderRow extends StatelessWidget {
  const _OpacitySliderRow({
    required this.value,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final VoidCallback onChangeStart;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeInstanceOpacity(value);
    final percent = (normalized * 100).round();
    final colors = context.pokeMapColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: PokeMapGuidedSlider(
        key: const ValueKey('placed-instance-opacity-slider'),
        label: 'Opacité',
        description: 'Transparence visuelle de cette instance',
        value: percent,
        onChangeStart: (_) => onChangeStart(),
        onChanged: (next) => onChanged(next / 100),
        onChangeEnd: (_) => onChangeEnd(),
      ),
    );
  }
}

double _normalizeInstanceOpacity(double value) =>
    (value.clamp(0.0, 1.0).toDouble() * 100).round() / 100;
