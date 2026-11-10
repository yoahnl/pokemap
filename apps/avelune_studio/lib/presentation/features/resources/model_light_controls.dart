import '../../../features/resources/application/model_light_draft.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/inputs/studio_slider.dart';
import '../../shared/widgets/inputs/studio_color_picker.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'model_light_preview_scope.dart';

class ModelLightControls extends StatefulWidget {
  const ModelLightControls({
    super.key,
    required this.model,
    required this.onSave,
    this.busy = false,
    this.previewController,
  });
  final ProjectModel3dEntry model;
  final Future<void> Function(Model3dPointLight?) onSave;
  final bool busy;
  final ModelPreviewController? previewController;
  @override
  State<ModelLightControls> createState() => _ModelLightControlsState();
}

class _ModelLightControlsState extends State<ModelLightControls> {
  late ModelLightDraft _draft;
  bool get saving => _draft.saving;
  bool get enabled => _draft.enabled;
  set enabled(bool value) => _draft.enabled = value;
  bool get nightOnly => _draft.nightOnly;
  set nightOnly(bool value) => _draft.nightOnly = value;
  bool get cycle => _draft.cycle;
  set cycle(bool value) => _draft.cycle = value;
  bool get flame => _draft.flame;
  set flame(bool value) => _draft.flame = value;
  int get color => _draft.color;
  set color(int value) => _draft.color = value;
  List<String> get values => _draft.values;
  set values(List<String> value) => _draft.values = value;
  List<int> get colors => _draft.colors;
  set colors(List<int> value) => _draft.colors = value;
  double get period => _draft.period;
  set period(double value) => _draft.period = value;
  double get enter => _draft.enter;
  set enter(double value) => _draft.enter = value;
  double get exit => _draft.exit;
  set exit(double value) => _draft.exit = value;
  double get fade => _draft.fade;
  set fade(double value) => _draft.fade = value;
  double get flameHeight => _draft.flameHeight;
  set flameHeight(double value) => _draft.flameHeight = value;
  double get flameFlicker => _draft.flameFlicker;
  set flameFlicker(double value) => _draft.flameFlicker = value;
  double get flameEmbers => _draft.flameEmbers;
  set flameEmbers(double value) => _draft.flameEmbers = value;
  double get flameCrackleVolume => _draft.flameCrackleVolume;
  set flameCrackleVolume(double value) => _draft.flameCrackleVolume = value;
  ModelLightFlameStyle get flameStyle => _draft.flameStyle;
  set flameStyle(ModelLightFlameStyle value) => _draft.flameStyle = value;
  String get proximity => _draft.proximity;
  set proximity(String value) => _draft.proximity = value;
  String? get error => _draft.error;
  set error(String? value) => _draft.error = value;
  ModelPreviewController? preview;
  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next =
        widget.previewController ?? ModelLightPreviewScope.maybeOf(context);
    if (!identical(next, preview)) {
      preview?.removeListener(moved);
      preview = next;
      preview?.addListener(moved);
    }
  }

  @override
  void didUpdateWidget(ModelLightControls old) {
    super.didUpdateWidget(old);
    if (old.model.id != widget.model.id ||
        old.model.light != widget.model.light) {
      _draft.dispose();
      reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) preview?.setLight(buildLight());
      });
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    preview?.removeListener(moved);
    super.dispose();
  }

  void reset() {
    _draft = ModelLightDraft(widget.model);
  }

  Model3dPointLight? buildLight() => _draft.build();

  void change(VoidCallback edit) {
    setState(edit);
    try {
      preview?.setLight(buildLight());
      error = null;
    } on FormatException catch (failure) {
      setState(() => error = failure.message);
    }
  }

  void moved() {
    final p = preview?.light?.localPosition;
    if (p == null || !mounted) return;
    if (_draft.move(p)) setState(() {});
  }

  Future<void> save() async {
    final owner = _draft;
    final saving = owner.save(
      widget.onSave,
      canSave: () => mounted && !widget.busy,
    );
    setState(() {});
    await saving;
    if (mounted && identical(_draft, owner)) setState(() {});
  }

  Widget slider(
    String key,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> update,
  ) => StudioSlider(
    key: ValueKey(key),
    label: label,
    value: value,
    min: min,
    max: max,
    valueLabel:
        '${value.toStringAsFixed(2)}${key.endsWith('seconds') ? ' s' : ''}',
    onChanged: saving || widget.busy ? null : (v) => change(() => update(v)),
  );
  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Éclairage',
    icon: Icons.lightbulb_outline,
    children: [
      StudioToggleRow(
        key: const ValueKey('model-light-enabled'),
        label: 'Émettre de la lumière',
        value: enabled,
        onChanged: saving || widget.busy
            ? null
            : (v) => change(() => enabled = v),
      ),
      if (enabled) ...[
        if (preview != null) ...[
          StudioToggleRow(
            key: const ValueKey('model-light-edit-bulb'),
            label: 'Déplacer l’ampoule dans l’aperçu',
            value: preview!.editLight,
            onChanged: (v) =>
                setState(() => preview!.configureLightEditor(editing: v)),
          ),
          StudioToggleRow(
            key: const ValueKey('model-light-preview-night'),
            label: 'Aperçu de nuit',
            value: preview!.nightPreview,
            onChanged: (v) =>
                setState(() => preview!.configureLightEditor(night: v)),
          ),
          const Text(
            'Glissez l’ampoule sur le plan horizontal ; utilisez X, Y et Z pour déplacer un seul axe.',
          ),
        ],
        const SizedBox(height: 8),
        for (final (i, label) in [
          'Position X',
          'Hauteur de la source',
          'Position Z',
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StudioDraftField(
              key: ValueKey('model-light-${['x', 'y', 'z'][i]}'),
              label: label,
              value: values[i],
              enabled: !saving && !widget.busy,
              onChanged: (v) => change(() => values[i] = v),
            ),
          ),
        slider(
          'model-light-radius',
          'Portée en cases',
          double.tryParse(values[3]) ?? 4,
          .25,
          16,
          (v) => values[3] = '$v',
        ),
        slider(
          'model-light-intensity',
          'Intensité',
          double.tryParse(values[4]) ?? 1,
          0,
          4,
          (v) => values[4] = '$v',
        ),
        StudioColorPicker(
          label: 'Couleur',
          colorRgb: color,
          presets: SpatialFireflyColor.values.map((v) => v.rgb).toList(),
          onChanged: saving || widget.busy
              ? null
              : (v) => change(() => color = v),
        ),
        const SizedBox(height: 12),
        StudioToggleRow(
          key: const ValueKey('model-light-night-only'),
          label: 'Allumer seulement la nuit',
          description: 'Allumage progressif au crépuscule. Désactivez cette option pour éclairer aussi en journée.',
          value: nightOnly,
          onChanged: saving || widget.busy
              ? null
              : (v) => change(() => nightOnly = v),
        ),
        StudioSelect(
          label: 'Animation de la lumière',
          value: cycle ? 'cycle' : 'fixed',
          options: const {
            'fixed': 'Couleur fixe',
            'cycle': 'Cycle de couleurs',
          },
          onChanged: saving || widget.busy
              ? null
              : (v) => change(() => cycle = v == 'cycle'),
        ),
        StudioToggleRow(
          key: const ValueKey('model-light-flame'),
          label: 'Flamme animée',
          description: 'Une bougie ou un brasier à la position de l’ampoule. Le feu et ses braises suivent les conditions d’allumage.',
          value: flame,
          onChanged: saving || widget.busy
              ? null
              : (v) => change(() => flame = v),
        ),
        if (flame) ...[
          StudioSelect(
            key: const ValueKey('model-light-flame-style'),
            label: 'Style du feu',
            value: flameStyle.name,
            options: const {'candle': 'Bougie', 'brazier': 'Brasier'},
            onChanged: saving || widget.busy
                ? null
                : (value) => change(
                    () =>
                        flameStyle = ModelLightFlameStyle.values.byName(value),
                  ),
          ),
          slider(
            'model-light-flame-height',
            'Hauteur de la flamme',
            flameHeight,
            .03,
            8,
            (v) => flameHeight = v,
          ),
          slider(
            'model-light-flame-flicker',
            'Vacillement de la flamme',
            flameFlicker,
            0,
            .4,
            (v) => flameFlicker = v,
          ),
          slider(
            'model-light-flame-embers',
            'Braises et étincelles',
            flameEmbers,
            0,
            1,
            (v) => flameEmbers = v,
          ),
          slider(
            'model-light-flame-crackle',
            'Volume du crépitement',
            flameCrackleVolume,
            0,
            1,
            (v) => flameCrackleVolume = v,
          ),
        ],
        if (cycle) ...[
          slider(
            'model-light-cycle-seconds',
            'Durée du cycle',
            period,
            2,
            120,
            (v) => period = v,
          ),
          for (var i = 0; i < colors.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: StudioColorPicker(
                      label: 'Couleur ${i + 1}',
                      colorRgb: colors[i],
                      presets: SpatialFireflyColor.values
                          .map((v) => v.rgb)
                          .toList(),
                      onChanged: saving || widget.busy
                          ? null
                          : (v) => change(() => colors[i] = v),
                    ),
                  ),
                  if (colors.length > 2)
                    StudioButton(
                      label: 'Retirer',
                      secondary: true,
                      onPressed: saving || widget.busy
                          ? null
                          : () => change(() => colors.removeAt(i)),
                    ),
                ],
              ),
            ),
          if (colors.length < 8)
            StudioButton(
              label: 'Ajouter une couleur',
              secondary: true,
              onPressed: saving || widget.busy
                  ? null
                  : () =>
                        change(() => colors.add(SpatialFireflyColor.pink.rgb)),
            ),
        ],
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Réagir à la proximité du joueur',
          value: proximity,
          options: const {
            'always': 'Aucune condition de distance',
            'near': 'S’allumer à l’approche',
            'far': 'S’éteindre à l’approche',
          },
          onChanged: saving || widget.busy
              ? null
              : (v) => change(() => proximity = v),
        ),
        if (proximity != 'always') ...[
          slider(
            'model-light-approach',
            'Distance d’approche en cases',
            enter,
            .25,
            32,
            (v) {
              enter = v;
              if (exit <= enter) exit = enter + .5;
            },
          ),
          slider(
            'model-light-leave',
            'Distance d’éloignement en cases',
            exit,
            enter + .01,
            64,
            (v) => exit = v,
          ),
          slider(
            'model-light-fade-seconds',
            'Transition douce',
            fade,
            .05,
            5,
            (v) => fade = v,
          ),
          const Text(
            'Deux distances évitent les allumages répétés quand le joueur reste à la limite.',
          ),
        ],
      ],
      if (error != null) StudioNotice(error!, isError: true),
      const SizedBox(height: 12),
      StudioButton(
        key: const ValueKey('model-light-save'),
        label: saving ? 'Enregistrement…' : 'Enregistrer l’éclairage',
        onPressed: saving || widget.busy ? null : save,
      ),
    ],
  );
}
