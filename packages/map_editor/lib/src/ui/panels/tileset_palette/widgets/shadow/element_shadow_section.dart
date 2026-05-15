import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';

class ElementShadowSection extends StatefulWidget {
  const ElementShadowSection({
    super.key,
    required this.manifest,
    required this.element,
    required this.shadow,
    required this.onChanged,
    this.onEnsureDefaultShadowProfiles,
  });

  final ProjectManifest manifest;
  final ProjectElementEntry element;
  final ProjectElementShadowConfig? shadow;
  final ValueChanged<ProjectElementShadowConfig?> onChanged;
  final VoidCallback? onEnsureDefaultShadowProfiles;

  @override
  State<ElementShadowSection> createState() => _ElementShadowSectionState();
}

class _ElementShadowSectionState extends State<ElementShadowSection> {
  late final TextEditingController _offsetXController;
  late final TextEditingController _offsetYController;
  late final TextEditingController _scaleXController;
  late final TextEditingController _scaleYController;
  late final TextEditingController _opacityController;
  final Map<_ShadowNumberField, String> _errors =
      <_ShadowNumberField, String>{};
  String? _activationMessage;

  @override
  void initState() {
    super.initState();
    _offsetXController = TextEditingController();
    _offsetYController = TextEditingController();
    _scaleXController = TextEditingController();
    _scaleYController = TextEditingController();
    _opacityController = TextEditingController();
    _syncControllers(widget.shadow);
  }

  @override
  void didUpdateWidget(covariant ElementShadowSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shadow != widget.shadow) {
      _syncControllers(widget.shadow);
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
    final element = widget.element.copyWith(shadow: widget.shadow);
    final readModel = buildElementShadowReadModel(
      manifest: widget.manifest,
      element: element,
    );
    final profiles = readModel.profileOptions;
    final selectedProfileId =
        readModel.profileExists ? readModel.shadowProfileId : null;
    final label = EditorChrome.primaryLabel(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final shadow = widget.shadow;
    final canCreateActiveShadow = profiles.isNotEmpty || shadow != null;

    return Container(
      key: const ValueKey('element-shadow-section'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ombre de l’élément',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _statusLabel(readModel.status),
                key: const ValueKey('element-shadow-status'),
                style: TextStyle(
                  color: _statusColor(context, readModel.status),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _summaryFor(readModel),
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          if (profiles.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aucun profil Shadow disponible.',
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoutez les profils par défaut pour commencer à configurer les ombres des éléments.',
              style: TextStyle(color: secondary, fontSize: 10),
            ),
            if (widget.onEnsureDefaultShadowProfiles != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: PushButton(
                  key: const ValueKey(
                    'element-shadow-default-profiles-button',
                  ),
                  controlSize: ControlSize.regular,
                  secondary: true,
                  onPressed: widget.onEnsureDefaultShadowProfiles,
                  child: const Text('Ajouter les profils Shadow par défaut'),
                ),
              ),
            ],
          ],
          if (_activationMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _activationMessage!,
              style: TextStyle(
                color: CupertinoColors.systemOrange.resolveFrom(context),
                fontSize: 10,
              ),
            ),
          ],
          ..._diagnosticWidgets(context, readModel),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Projette une ombre',
                  style: TextStyle(color: label, fontSize: 11),
                ),
              ),
              CupertinoSwitch(
                key: const ValueKey('element-shadow-casts-switch'),
                value: shadow?.castsShadow ?? false,
                onChanged: canCreateActiveShadow ? _setCastsShadow : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _profilePicker(
            context: context,
            profiles: profiles,
            selectedProfileId: selectedProfileId,
            enabled: profiles.isNotEmpty && shadow != null,
          ),
          if (shadow != null) ...[
            const SizedBox(height: 10),
            _numberGrid(context),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: PushButton(
                key: const ValueKey('element-shadow-reset-button'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () {
                  setState(() {
                    _errors.clear();
                    _activationMessage = null;
                  });
                  widget.onChanged(null);
                },
                child: const Text('Réinitialiser la config'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _profilePicker({
    required BuildContext context,
    required List<ShadowProfileOptionReadModel> profiles,
    required String? selectedProfileId,
    required bool enabled,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final items = profiles.map((profile) {
      return MacosPopupMenuItem<String>(
        value: profile.id,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            '${profile.name} (${profile.id})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil',
          style: TextStyle(color: secondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        MacosPopupButton<String>(
          key: const ValueKey('element-shadow-profile-popup'),
          items: items,
          value: selectedProfileId,
          hint: const Text('Choisir un profil'),
          disabledHint: const Text('Aucun profil disponible'),
          onChanged: enabled
              ? (profileId) {
                  if (profileId == null) return;
                  _setProfile(profileId);
                }
              : null,
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
              child: _numberField(context, _ShadowNumberField.offsetX),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(context, _ShadowNumberField.offsetY),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _numberField(context, _ShadowNumberField.scaleX),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _numberField(context, _ShadowNumberField.scaleY),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _numberField(context, _ShadowNumberField.opacity),
      ],
    );
  }

  Widget _numberField(BuildContext context, _ShadowNumberField field) {
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
          key: ValueKey('element-shadow-${field.keyName}-field'),
          controller: _controllerFor(field),
          enabled: widget.shadow != null,
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

  void _setCastsShadow(bool value) {
    final current = widget.shadow;
    if (!value) {
      if (current == null) return;
      widget.onChanged(
        ProjectElementShadowConfig(
          castsShadow: false,
          shadowProfileId: current.shadowProfileId,
          offsetX: current.offsetX,
          offsetY: current.offsetY,
          scaleX: current.scaleX,
          scaleY: current.scaleY,
          opacity: current.opacity,
        ),
      );
      return;
    }

    final profiles = buildShadowProfileOptionsForManifest(widget.manifest);
    if (profiles.isEmpty) {
      setState(() {
        _activationMessage = 'Aucun profil Shadow disponible.';
      });
      return;
    }

    final currentProfileId = current?.shadowProfileId;
    final selectedProfileId = currentProfileId != null &&
            profiles.any((profile) => profile.id == currentProfileId)
        ? currentProfileId
        : profiles.first.id;
    setState(() {
      _activationMessage = null;
    });
    widget.onChanged(
      ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: selectedProfileId,
        offsetX: current?.offsetX,
        offsetY: current?.offsetY,
        scaleX: current?.scaleX,
        scaleY: current?.scaleY,
        opacity: current?.opacity,
      ),
    );
  }

  void _setProfile(String profileId) {
    final current = widget.shadow;
    widget.onChanged(
      ProjectElementShadowConfig(
        castsShadow: current?.castsShadow ?? true,
        shadowProfileId: profileId,
        offsetX: current?.offsetX,
        offsetY: current?.offsetY,
        scaleX: current?.scaleX,
        scaleY: current?.scaleY,
        opacity: current?.opacity,
      ),
    );
  }

  void _setNumber(_ShadowNumberField field, String rawValue) {
    final current = widget.shadow;
    if (current == null) return;
    final value = _parseNumber(field, rawValue);
    if (value?.isNaN == true) return;

    widget.onChanged(
      ProjectElementShadowConfig(
        castsShadow: current.castsShadow,
        shadowProfileId: current.shadowProfileId,
        offsetX: field == _ShadowNumberField.offsetX ? value : current.offsetX,
        offsetY: field == _ShadowNumberField.offsetY ? value : current.offsetY,
        scaleX: field == _ShadowNumberField.scaleX ? value : current.scaleX,
        scaleY: field == _ShadowNumberField.scaleY ? value : current.scaleY,
        opacity: field == _ShadowNumberField.opacity ? value : current.opacity,
      ),
    );
  }

  double? _parseNumber(_ShadowNumberField field, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      setState(() => _errors.remove(field));
      return null;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) {
      setState(() => _errors[field] = '${field.label} invalide.');
      return _invalidNumber;
    }
    if ((field == _ShadowNumberField.scaleX ||
            field == _ShadowNumberField.scaleY) &&
        parsed <= 0) {
      setState(() => _errors[field] = '${field.label} doit être > 0.');
      return _invalidNumber;
    }
    if (field == _ShadowNumberField.opacity && (parsed < 0 || parsed > 1)) {
      setState(() => _errors[field] = 'Opacité doit être entre 0 et 1.');
      return _invalidNumber;
    }
    setState(() => _errors.remove(field));
    return parsed;
  }

  void _syncControllers(ProjectElementShadowConfig? shadow) {
    _offsetXController.text = _formatNumber(shadow?.offsetX);
    _offsetYController.text = _formatNumber(shadow?.offsetY);
    _scaleXController.text = _formatNumber(shadow?.scaleX);
    _scaleYController.text = _formatNumber(shadow?.scaleY);
    _opacityController.text = _formatNumber(shadow?.opacity);
  }

  TextEditingController _controllerFor(_ShadowNumberField field) {
    switch (field) {
      case _ShadowNumberField.offsetX:
        return _offsetXController;
      case _ShadowNumberField.offsetY:
        return _offsetYController;
      case _ShadowNumberField.scaleX:
        return _scaleXController;
      case _ShadowNumberField.scaleY:
        return _scaleYController;
      case _ShadowNumberField.opacity:
        return _opacityController;
    }
  }
}

const double _invalidNumber = double.nan;

enum _ShadowNumberField {
  offsetX('offsetX', 'Offset X'),
  offsetY('offsetY', 'Offset Y'),
  scaleX('scaleX', 'Scale X'),
  scaleY('scaleY', 'Scale Y'),
  opacity('opacity', 'Opacité');

  const _ShadowNumberField(this.keyName, this.label);

  final String keyName;
  final String label;
}

String _statusLabel(ElementShadowReadStatus status) {
  switch (status) {
    case ElementShadowReadStatus.notConfigured:
      return 'Non configurée';
    case ElementShadowReadStatus.disabled:
      return 'Désactivée';
    case ElementShadowReadStatus.active:
      return 'Active';
    case ElementShadowReadStatus.missingProfile:
      return 'Profil manquant';
    case ElementShadowReadStatus.profileNone:
      return 'Profil sans ombre';
  }
}

Color _statusColor(BuildContext context, ElementShadowReadStatus status) {
  switch (status) {
    case ElementShadowReadStatus.active:
      return CupertinoColors.systemGreen.resolveFrom(context);
    case ElementShadowReadStatus.missingProfile:
      return CupertinoColors.systemRed.resolveFrom(context);
    case ElementShadowReadStatus.profileNone:
      return CupertinoColors.systemBlue.resolveFrom(context);
    case ElementShadowReadStatus.disabled:
      return CupertinoColors.systemOrange.resolveFrom(context);
    case ElementShadowReadStatus.notConfigured:
      return CupertinoColors.secondaryLabel.resolveFrom(context);
  }
}

String _summaryFor(ElementShadowReadModel readModel) {
  switch (readModel.status) {
    case ElementShadowReadStatus.notConfigured:
      return 'Aucune config Shadow sur cet élément.';
    case ElementShadowReadStatus.disabled:
      return 'Config conservée, ombre désactivée.';
    case ElementShadowReadStatus.active:
      final name = readModel.shadowProfileName ?? readModel.shadowProfileId;
      return 'Profil actif : $name.';
    case ElementShadowReadStatus.missingProfile:
      return 'Choisis un profil valide ou réinitialise la config.';
    case ElementShadowReadStatus.profileNone:
      return 'Le profil sélectionné exprime volontairement aucune ombre.';
  }
}

List<Widget> _diagnosticWidgets(
  BuildContext context,
  ElementShadowReadModel readModel,
) {
  if (readModel.diagnostics.isEmpty) {
    if (readModel.status == ElementShadowReadStatus.missingProfile &&
        readModel.shadowProfileId != null) {
      return [
        const SizedBox(height: 8),
        _diagnosticText(
          context,
          'Profil Shadow introuvable : ${readModel.shadowProfileId}',
          isError: true,
        ),
      ];
    }
    return const <Widget>[];
  }
  return <Widget>[
    const SizedBox(height: 8),
    for (final diagnostic in readModel.diagnostics)
      _diagnosticText(
        context,
        diagnostic.code == 'missingShadowProfile' &&
                readModel.shadowProfileId != null
            ? 'Profil Shadow introuvable : ${readModel.shadowProfileId}'
            : diagnostic.message,
        isError: diagnostic.severity == ElementShadowDiagnosticSeverity.error,
      ),
  ];
}

Widget _diagnosticText(
  BuildContext context,
  String message, {
  required bool isError,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      message,
      style: TextStyle(
        color:
            (isError ? CupertinoColors.systemRed : CupertinoColors.systemOrange)
                .resolveFrom(context),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _formatNumber(double? value) {
  if (value == null) return '';
  return value.toString();
}
