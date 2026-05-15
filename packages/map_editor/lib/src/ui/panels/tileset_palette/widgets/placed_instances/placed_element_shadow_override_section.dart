import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_override_read_model.dart';
import 'package:map_editor/src/application/shadow/placed_element_shadow_tuning_presets.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';

class PlacedElementShadowOverrideSection extends StatefulWidget {
  const PlacedElementShadowOverrideSection({
    super.key,
    required this.manifest,
    required this.element,
    required this.instance,
    required this.shadowOverride,
    required this.onChanged,
    required this.onEnsureDefaultShadowProfiles,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry? element;
  final MapPlacedElement instance;
  final MapPlacedElementShadowOverride? shadowOverride;
  final ValueChanged<MapPlacedElementShadowOverride?> onChanged;
  final VoidCallback onEnsureDefaultShadowProfiles;

  @override
  State<PlacedElementShadowOverrideSection> createState() =>
      _PlacedElementShadowOverrideSectionState();
}

class _PlacedElementShadowOverrideSectionState
    extends State<PlacedElementShadowOverrideSection> {
  late final TextEditingController _offsetXController;
  late final TextEditingController _offsetYController;
  late final TextEditingController _scaleXController;
  late final TextEditingController _scaleYController;
  late final TextEditingController _opacityController;
  final Map<_PlacedShadowNumberField, String> _errors =
      <_PlacedShadowNumberField, String>{};

  @override
  void initState() {
    super.initState();
    _offsetXController = TextEditingController();
    _offsetYController = TextEditingController();
    _scaleXController = TextEditingController();
    _scaleYController = TextEditingController();
    _opacityController = TextEditingController();
    _syncControllers(widget.shadowOverride);
  }

  @override
  void didUpdateWidget(covariant PlacedElementShadowOverrideSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shadowOverride != widget.shadowOverride) {
      _syncControllers(widget.shadowOverride);
    }
  }

  @override
  void dispose() {
    _offsetXController.dispose();
    _offsetYController.dispose();
    _scaleXController.dispose();
    _scaleYController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instance = widget.instance.copyWith(
      shadowOverride: widget.shadowOverride,
    );
    final readModel = buildPlacedElementShadowOverrideReadModel(
      manifest: widget.manifest,
      element: widget.element,
      instance: instance,
    );
    final label = EditorChrome.primaryLabel(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      key: const ValueKey('placed-shadow-override-section'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ombre de cette instance',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Modifie seulement cet élément placé, sans changer l’élément source.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          if (readModel.sourceShadowMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              readModel.sourceShadowMessage!,
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (readModel.noCompatibleProfileMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              readModel.noCompatibleProfileMessage!,
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                key: const ValueKey(
                  'placed-shadow-default-profiles-button',
                ),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: widget.onEnsureDefaultShadowProfiles,
                child: const Text('Ajouter les profils Shadow par défaut'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          CupertinoSlidingSegmentedControl<PlacedElementShadowOverrideUiMode>(
            groupValue: readModel.mode,
            children: const {
              PlacedElementShadowOverrideUiMode.inherit: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Hériter', style: TextStyle(fontSize: 10)),
              ),
              PlacedElementShadowOverrideUiMode.disabled: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Désactiver', style: TextStyle(fontSize: 10)),
              ),
              PlacedElementShadowOverrideUiMode.custom: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text('Personnaliser', style: TextStyle(fontSize: 10)),
              ),
            },
            onValueChanged: (mode) {
              if (mode == null) return;
              _setMode(mode);
            },
          ),
          const SizedBox(height: 8),
          _modeHelp(context, readModel.mode),
          if (readModel.mode == PlacedElementShadowOverrideUiMode.custom) ...[
            const SizedBox(height: 10),
            _profilePicker(
              context: context,
              profiles: readModel.profileOptions,
              selectedProfileId: readModel.selectedProfileId,
            ),
            const SizedBox(height: 10),
            _quickTuningPresets(context),
            const SizedBox(height: 10),
            _numberGrid(context),
          ],
          if (widget.shadowOverride != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                key: const ValueKey('placed-shadow-reset-button'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () {
                  setState(_errors.clear);
                  widget.onChanged(null);
                },
                child: const Text('Réinitialiser l’override'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeHelp(
    BuildContext context,
    PlacedElementShadowOverrideUiMode mode,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final message = switch (mode) {
      PlacedElementShadowOverrideUiMode.inherit =>
        'Cette instance utilise l’ombre configurée sur l’élément source.',
      PlacedElementShadowOverrideUiMode.disabled =>
        'Cette instance ne projettera aucune ombre.',
      PlacedElementShadowOverrideUiMode.custom =>
        'Cette instance personnalise son profil, son décalage, son échelle ou son opacité.',
    };
    return Text(
      message,
      style: TextStyle(color: secondary, fontSize: 10),
    );
  }

  Widget _profilePicker({
    required BuildContext context,
    required List<ShadowProfileOptionReadModel> profiles,
    required String? selectedProfileId,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final items = <MacosPopupMenuItem<String>>[
      const MacosPopupMenuItem<String>(
        value: _inheritProfileValue,
        child: Text('Hériter du profil de l’élément'),
      ),
      ...profiles.map(
        (profile) => MacosPopupMenuItem<String>(
          value: profile.id,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              '${profile.name} (${profile.id})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil Shadow',
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        MacosPopupButton<String>(
          key: const ValueKey('placed-shadow-profile-popup'),
          items: items,
          value: selectedProfileId ?? _inheritProfileValue,
          onChanged: (profileId) {
            if (profileId == null) return;
            _setProfile(
              profileId == _inheritProfileValue ? null : profileId,
            );
          },
        ),
      ],
    );
  }

  Widget _quickTuningPresets(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final presets = createPlacedElementShadowTuningPresets();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réglages rapides',
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          'Applique des réglages rapides à cette instance. Vous pouvez ensuite affiner les valeurs manuellement.',
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in presets)
              PushButton(
                key: ValueKey('placed-shadow-preset-${preset.id}-button'),
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: () => _applyTuningPreset(preset),
                child: Text(preset.label),
              ),
          ],
        ),
      ],
    );
  }

  Widget _numberGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.offsetX),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.offsetY),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.scaleX),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(context, _PlacedShadowNumberField.scaleY),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _numberField(context, _PlacedShadowNumberField.opacity),
      ],
    );
  }

  Widget _numberField(
    BuildContext context,
    _PlacedShadowNumberField field,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final error = _errors[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        MacosTextField(
          key: ValueKey('placed-shadow-${field.keyName}-field'),
          controller: _controllerFor(field),
          placeholder: 'auto',
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          onChanged: (value) => _setNumber(field, value),
        ),
        if (error != null) ...[
          const SizedBox(height: 3),
          Text(
            error,
            style: TextStyle(
              color: CupertinoColors.systemRed.resolveFrom(context),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  void _setMode(PlacedElementShadowOverrideUiMode mode) {
    setState(_errors.clear);
    switch (mode) {
      case PlacedElementShadowOverrideUiMode.inherit:
        widget.onChanged(null);
      case PlacedElementShadowOverrideUiMode.disabled:
        widget.onChanged(
          MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.disabled,
          ),
        );
      case PlacedElementShadowOverrideUiMode.custom:
        widget.onChanged(_customOverride());
    }
  }

  void _setProfile(String? profileId) {
    widget.onChanged(
      _customOverride(shadowProfileId: profileId),
    );
  }

  void _setNumber(_PlacedShadowNumberField field, String rawValue) {
    final parsed = _parseNumber(field, rawValue);
    if (parsed?.isNaN == true) return;
    final current = _currentCustomOverride;
    widget.onChanged(
      _customOverride(
        offsetX: field == _PlacedShadowNumberField.offsetX
            ? parsed
            : current?.offsetX,
        offsetY: field == _PlacedShadowNumberField.offsetY
            ? parsed
            : current?.offsetY,
        scaleX:
            field == _PlacedShadowNumberField.scaleX ? parsed : current?.scaleX,
        scaleY:
            field == _PlacedShadowNumberField.scaleY ? parsed : current?.scaleY,
        opacity: field == _PlacedShadowNumberField.opacity
            ? parsed
            : current?.opacity,
      ),
    );
  }

  void _applyTuningPreset(PlacedElementShadowTuningPreset preset) {
    setState(_errors.clear);
    widget.onChanged(
      applyPlacedElementShadowTuningPreset(
        preset: preset,
        currentOverride: widget.shadowOverride,
      ),
    );
  }

  double? _parseNumber(_PlacedShadowNumberField field, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      setState(() => _errors.remove(field));
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) {
      setState(() => _errors[field] = 'Nombre invalide');
      return _invalidPlacedShadowNumber;
    }
    if ((field == _PlacedShadowNumberField.scaleX ||
            field == _PlacedShadowNumberField.scaleY) &&
        parsed <= 0) {
      setState(() => _errors[field] = 'Doit être > 0');
      return _invalidPlacedShadowNumber;
    }
    if (field == _PlacedShadowNumberField.opacity &&
        (parsed < 0 || parsed > 1)) {
      setState(() => _errors[field] = 'Doit être entre 0 et 1');
      return _invalidPlacedShadowNumber;
    }
    setState(() => _errors.remove(field));
    return parsed;
  }

  MapPlacedElementShadowOverride _customOverride({
    Object? shadowProfileId = _preservePlacedShadowValue,
    Object? offsetX = _preservePlacedShadowValue,
    Object? offsetY = _preservePlacedShadowValue,
    Object? scaleX = _preservePlacedShadowValue,
    Object? scaleY = _preservePlacedShadowValue,
    Object? opacity = _preservePlacedShadowValue,
  }) {
    final current = _currentCustomOverride;
    return MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.custom,
      shadowProfileId: identical(shadowProfileId, _preservePlacedShadowValue)
          ? current?.shadowProfileId
          : shadowProfileId as String?,
      offsetX: identical(offsetX, _preservePlacedShadowValue)
          ? current?.offsetX
          : offsetX as double?,
      offsetY: identical(offsetY, _preservePlacedShadowValue)
          ? current?.offsetY
          : offsetY as double?,
      scaleX: identical(scaleX, _preservePlacedShadowValue)
          ? current?.scaleX
          : scaleX as double?,
      scaleY: identical(scaleY, _preservePlacedShadowValue)
          ? current?.scaleY
          : scaleY as double?,
      opacity: identical(opacity, _preservePlacedShadowValue)
          ? current?.opacity
          : opacity as double?,
    );
  }

  MapPlacedElementShadowOverride? get _currentCustomOverride {
    final current = widget.shadowOverride;
    if (current?.mode != ShadowOverrideMode.custom) {
      return null;
    }
    return current;
  }

  void _syncControllers(MapPlacedElementShadowOverride? override) {
    _offsetXController.text = _formatPlacedShadowNumber(override?.offsetX);
    _offsetYController.text = _formatPlacedShadowNumber(override?.offsetY);
    _scaleXController.text = _formatPlacedShadowNumber(override?.scaleX);
    _scaleYController.text = _formatPlacedShadowNumber(override?.scaleY);
    _opacityController.text = _formatPlacedShadowNumber(override?.opacity);
  }

  TextEditingController _controllerFor(_PlacedShadowNumberField field) {
    switch (field) {
      case _PlacedShadowNumberField.offsetX:
        return _offsetXController;
      case _PlacedShadowNumberField.offsetY:
        return _offsetYController;
      case _PlacedShadowNumberField.scaleX:
        return _scaleXController;
      case _PlacedShadowNumberField.scaleY:
        return _scaleYController;
      case _PlacedShadowNumberField.opacity:
        return _opacityController;
    }
  }
}

const String _inheritProfileValue = '__inherit__';
const double _invalidPlacedShadowNumber = double.nan;
const Object _preservePlacedShadowValue = Object();

enum _PlacedShadowNumberField {
  offsetX('offsetX', 'Offset X'),
  offsetY('offsetY', 'Offset Y'),
  scaleX('scaleX', 'Scale X'),
  scaleY('scaleY', 'Scale Y'),
  opacity('opacity', 'Opacité');

  const _PlacedShadowNumberField(this.keyName, this.label);

  final String keyName;
  final String label;
}

String _formatPlacedShadowNumber(double? value) {
  if (value == null) return '';
  return value.toString();
}
