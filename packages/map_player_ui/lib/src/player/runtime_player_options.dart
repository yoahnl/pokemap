import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_control_profile.dart';
import 'player_control_strings.dart';
import 'player_options_strings.dart';
import 'runtime_player_actions.dart';

final class RuntimePlayerOptionsFailure implements Exception {
  const RuntimePlayerOptionsFailure(this.safeMessage);
  final String safeMessage;
}

final class RuntimePlayerOptionsNavigation extends ChangeNotifier {
  bool Function()? _back;
  Widget Function(BuildContext, Widget?)? _actions;
  String Function()? _title;
  Widget Function(BuildContext)? _header;
  ValueChanged<int>? _stepTab;
  Object Function()? _tabIdentity;

  String? get activeTitle => _title?.call();
  Object? get tabIdentity => _tabIdentity?.call();
  void previousTab() => _stepTab?.call(-1);
  void nextTab() => _stepTab?.call(1);
  Widget buildHeaderAction(BuildContext context) =>
      _header?.call(context) ?? const SizedBox.shrink();

  bool back() => _back?.call() ?? false;
  Widget buildActions(BuildContext context, {Widget? returnAction}) =>
      _actions?.call(context, returnAction) ??
      returnAction ??
      const SizedBox.shrink();
  void refresh() => notifyListeners();
}

class RuntimePlayerOptions extends StatefulWidget {
  const RuntimePlayerOptions({
    super.key,
    required this.preferences,
    this.defaultPreferences = const PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
    ),
    this.onChanged,
    this.navigation,
    this.onReturnToTitle,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
    this.onControlProfileChanged,
    this.activeInputSource = PlayerInputSource.keyboard,
  });

  final PlayerPreferencesSnapshot preferences;
  final PlayerPreferencesSnapshot defaultPreferences;
  final FutureOr<void> Function(PlayerPreferencesSnapshot)? onChanged;
  final RuntimePlayerOptionsNavigation? navigation;
  final VoidCallback? onReturnToTitle;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  final FutureOr<void> Function(PlayerControlProfile)? onControlProfileChanged;
  final PlayerInputSource activeInputSource;

  @override
  State<RuntimePlayerOptions> createState() => _RuntimePlayerOptionsState();
}

class _RuntimePlayerOptionsState extends State<RuntimePlayerOptions> {
  late PlayerPreferencesSnapshot _confirmed = widget.preferences;
  late PlayerControlProfile _profile =
      widget.controlProfile ?? PlayerControlProfile.standard;
  final _drafts = <String, double>{};
  final _sliderFocus = <String, FocusNode>{};
  final _choiceFocus = <String, FocusNode>{};
  final _categoryFocus = FocusScopeNode(debugLabel: 'Options categories');
  final _settingsFocus = FocusScopeNode(debugLabel: 'Options settings');
  PlayerOptionsCategory _category = PlayerOptionsCategory.general;
  bool _showCategories = false;
  bool _showTouchSettings = false;
  bool get _showBindings =>
      widget.activeInputSource != PlayerInputSource.touch &&
      !_showTouchSettings;
  bool _pending = false;
  bool _failed = false;
  String? _saveError;
  String? _controlError;
  DialogRoute<dynamic>? _dialogRoute;

  PlayerOptionsStrings get _strings => PlayerOptionsStrings.of(context);
  bool get _enabled => widget.onChanged != null && !_pending;
  bool get _hapticsSupported => switch (Theme.of(context).platform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    widget.navigation?._back = _back;
    widget.navigation?._actions = _actions;
    widget.navigation?._title = () => _showCategories
        ? _strings.text('Options', 'Options')
        : _strings.category(_category);
    widget.navigation?._header = (_) => _headerAction();
    widget.navigation?._stepTab = _stepCategory;
    widget.navigation?._tabIdentity = () => (_category, _showCategories);
  }

  @override
  void didUpdateWidget(RuntimePlayerOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      oldWidget.navigation?._back = null;
      oldWidget.navigation?._actions = null;
      oldWidget.navigation?._title = null;
      oldWidget.navigation?._header = null;
      oldWidget.navigation?._stepTab = null;
      oldWidget.navigation?._tabIdentity = null;
      _bind();
    }
    if (!_pending && !identical(oldWidget.preferences, widget.preferences)) {
      _confirmed = widget.preferences;
      _drafts.clear();
    }
    if (!_pending && oldWidget.controlProfile != widget.controlProfile) {
      _profile = widget.controlProfile ?? PlayerControlProfile.standard;
    }
  }

  @override
  void dispose() {
    widget.navigation?._back = null;
    widget.navigation?._actions = null;
    widget.navigation?._title = null;
    widget.navigation?._header = null;
    widget.navigation?._stepTab = null;
    widget.navigation?._tabIdentity = null;
    final route = _dialogRoute;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    for (final node in _sliderFocus.values) {
      node.dispose();
    }
    for (final node in _choiceFocus.values) {
      node.dispose();
    }
    _categoryFocus.dispose();
    _settingsFocus.dispose();
    super.dispose();
  }

  Future<void> _save(
    PlayerPreferencesSnapshot next, {
    FocusNode? focusAfterSave,
  }) async {
    if (!mounted || !_enabled) return;
    RuntimePlayerLocalActionNotification().dispatch(context);
    final previousWidget = widget.preferences;
    final previousFocus = focusAfterSave ?? FocusManager.instance.primaryFocus;
    setState(() {
      _pending = true;
      _failed = false;
    });
    try {
      await widget.onChanged!(next);
      if (!mounted) return;
      setState(() {
        _confirmed = identical(previousWidget, widget.preferences)
            ? next
            : widget.preferences;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _saveError = error is RuntimePlayerOptionsFailure
              ? error.safeMessage
              : null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
          _drafts.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _dialogRoute == null &&
              previousFocus?.context != null &&
              previousFocus!.canRequestFocus) {
            previousFocus.requestFocus();
          }
        });
      }
    }
  }

  Future<void> _saveProfile(
    PlayerControlProfile next, {
    FocusNode? focusAfterSave,
  }) async {
    if (!mounted || _pending || widget.onControlProfileChanged == null) return;
    RuntimePlayerLocalActionNotification().dispatch(context);
    setState(() {
      _pending = true;
      _failed = false;
      _controlError = null;
    });
    try {
      await widget.onControlProfileChanged!(next);
      if (mounted) setState(() => _profile = next);
    } catch (error) {
      if (mounted) {
        setState(() {
          _failed = true;
          _saveError = error is RuntimePlayerOptionsFailure
              ? error.safeMessage
              : null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _pending = false);
        _restoreChoiceFocus(focusAfterSave);
      }
    }
  }

  FocusNode _choiceNode(String id) =>
      _choiceFocus.putIfAbsent(id, () => FocusNode(debugLabel: 'Option: $id'));

  void _restoreChoiceFocus(FocusNode? node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _dialogRoute == null &&
          node?.context != null &&
          node!.canRequestFocus) {
        node.requestFocus();
      }
    });
  }

  void _select(PlayerOptionsCategory category) {
    if (_pending) return;
    RuntimePlayerLocalActionNotification().dispatch(context);
    setState(() {
      _category = category;
      _showCategories = false;
      _drafts.clear();
    });
  }

  void _stepCategory(int delta) {
    if (_pending) return;
    _select(
      PlayerOptionsCategory.values[(_category.index + delta) %
          PlayerOptionsCategory.values.length],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settingsFocus.requestFocus();
    });
  }

  Object? _input(RuntimePlayerLogicalIntent intent) {
    if (_pending && intent.action != PlayerInputAction.back) return null;
    if (intent.action == PlayerInputAction.previousTab ||
        intent.action == PlayerInputAction.nextTab) {
      RuntimePlayerInputSourceNotification(intent.source).dispatch(context);
      final delta = intent.action == PlayerInputAction.nextTab ? 1 : -1;
      _stepCategory(delta);
      return null;
    }
    if (intent.action == PlayerInputAction.left && _settingsFocus.hasFocus) {
      _categoryFocus.requestFocus();
      return null;
    }
    if (intent.action == PlayerInputAction.right && _categoryFocus.hasFocus) {
      _settingsFocus.requestFocus();
      return null;
    }
    if (intent.action == PlayerInputAction.back && _back()) return null;
    return Actions.maybeInvoke(context, intent);
  }

  bool _back() {
    if (!_showCategories) return false;
    RuntimePlayerLocalActionNotification().dispatch(context);
    setState(() => _showCategories = false);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.navigation?.refresh();
    });
    return RuntimePlayerInputBindings(
      controlProfile: _profile,
      hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
      child: RuntimePlayerTabActions(
        resetToken: _category,
        onPreviousTab: () => _stepCategory(-1),
        onNextTab: () => _stepCategory(1),
        child: _buildOptions(context),
      ),
    );
  }

  Widget _buildOptions(BuildContext context) => Actions(
    actions: {
      RuntimePlayerLogicalIntent: CallbackAction<RuntimePlayerLogicalIntent>(
        onInvoke: _input,
      ),
    },
    child: LayoutBuilder(
      builder: (context, constraints) {
        final horizontalTabs =
            widget.navigation == null &&
            constraints.maxWidth >= 600 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        return Column(
          key: const ValueKey('runtime-player-options'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (horizontalTabs) ...[
              _categoryTabs(),
              const SizedBox(height: 8),
            ] else if (widget.navigation == null && !_showCategories) ...[
              Row(
                children: [
                  Expanded(child: _categoryStepButton(-1)),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _categoryPicker()),
                  const SizedBox(width: 8),
                  Expanded(child: _categoryStepButton(1)),
                  if (_category == PlayerOptionsCategory.controls &&
                      widget.activeInputSource != PlayerInputSource.touch) ...[
                    const SizedBox(width: 8),
                    _controlDeviceSwitch(),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            Expanded(child: _showCategories ? _categories() : _settings(true)),
          ],
        );
      },
    ),
  );

  Widget _headerAction() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_category == PlayerOptionsCategory.controls &&
          widget.activeInputSource != PlayerInputSource.touch) ...[
        _controlDeviceSwitch(),
        const SizedBox(width: 8),
      ],
      IconButton(
        key: const ValueKey('options-category-picker'),
        tooltip: _strings.text('Catégories des options', 'Options categories'),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: const Icon(Icons.menu_rounded),
        onPressed: _pending
            ? null
            : () {
                RuntimePlayerLocalActionNotification().dispatch(context);
                setState(() => _showCategories = !_showCategories);
              },
      ),
    ],
  );

  Widget _categoryPicker() {
    if (MediaQuery.sizeOf(context).height < 480 &&
        MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
      return Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          key: const ValueKey('options-category-picker'),
          tooltip: _strings.category(_category),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: const Icon(Icons.menu_rounded),
          onPressed: _pending
              ? null
              : () => setState(() => _showCategories = !_showCategories),
        ),
      );
    }
    return PlayerActionButton(
      key: const ValueKey('options-category-picker'),
      label: _strings.category(_category),
      labelMaxLines: 3,
      expandContent: true,
      icon: Icons.menu_rounded,
      secondary: true,
      onPressed: _pending
          ? null
          : () {
              RuntimePlayerLocalActionNotification().dispatch(context);
              setState(() => _showCategories = !_showCategories);
            },
    );
  }

  Widget _categoryTabs() => SizedBox(
    height: 48,
    child: Row(
      children: [
        for (var i = 0; i < PlayerOptionsCategory.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            flex: _strings
                .category(PlayerOptionsCategory.values[i])
                .length
                .clamp(5, 14),
            child: PlayerMenuSelectableRow(
              key: ValueKey(
                'options-category-${PlayerOptionsCategory.values[i].name}',
              ),
              id: 'options-category-${PlayerOptionsCategory.values[i].name}',
              label: _strings.category(PlayerOptionsCategory.values[i]),
              tab: true,
              labelMaxLines: 1,
              labelStyle: context.playerMenuTheme.label.copyWith(fontSize: 14),
              reserveFocusMarker: false,
              integrated: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 2),
              selected: _category == PlayerOptionsCategory.values[i],
              onPressed: _pending
                  ? null
                  : () => _select(PlayerOptionsCategory.values[i]),
            ),
          ),
        ],
        if (_category == PlayerOptionsCategory.controls &&
            widget.activeInputSource != PlayerInputSource.touch) ...[
          const SizedBox(width: 8),
          _controlDeviceSwitch(),
        ],
        if (widget.onReturnToTitle != null) ...[
          const SizedBox(width: 8),
          IconButton(
            key: const ValueKey('options-return-title'),
            tooltip: _strings.text('Retour au titre', 'Return to title'),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: _pending ? null : widget.onReturnToTitle,
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ],
    ),
  );

  Widget _controlDeviceSwitch() => IconButton(
    key: const ValueKey('options-control-device-switch'),
    tooltip: _showBindings
        ? _strings.text('Réglages tactiles', 'Touch settings')
        : PlayerControlStrings.of(context).device(
            widget.activeInputSource == PlayerInputSource.controller
                ? PlayerControlDevice.gamepad
                : PlayerControlDevice.keyboard,
          ),
    constraints: const BoxConstraints.tightFor(width: 48, height: 48),
    icon: Icon(
      _showBindings
          ? Icons.touch_app_rounded
          : widget.activeInputSource == PlayerInputSource.controller
          ? Icons.gamepad_rounded
          : Icons.keyboard_rounded,
    ),
    onPressed: _pending
        ? null
        : () => setState(() => _showTouchSettings = !_showTouchSettings),
  );

  Widget _categoryStepButton(int delta) {
    final category =
        PlayerOptionsCategory.values[(_category.index + delta) %
            PlayerOptionsCategory.values.length];
    final label = _strings.category(category);
    final direction = delta < 0 ? 'previous' : 'next';
    final announcement = delta < 0
        ? _strings.text('Catégorie précédente', 'Previous category')
        : _strings.text('Catégorie suivante', 'Next category');
    final icon = Icon(
      delta < 0 ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: 20,
    );
    return Tooltip(
      message: '$announcement : $label',
      child: PlayerMenuSelectableRow(
        key: ValueKey('options-category-$direction'),
        id: 'options-category-$direction',
        label: label,
        semanticValue: announcement,
        leading: delta < 0 ? icon : null,
        trailing: delta > 0 ? icon : null,
        trailingWidth: delta > 0 ? 20 : null,
        labelStyle: context.playerMenuTheme.meta,
        labelMaxLines: 3,
        reserveFocusMarker: false,
        minimumHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        onPressed: _pending ? null : () => _stepCategory(delta),
      ),
    );
  }

  Widget _actions(
    BuildContext context, [
    Widget? returnAction,
  ]) => LayoutBuilder(
    builder: (context, constraints) {
      final returnWidth = 88 * MediaQuery.textScalerOf(context).scale(1);
      final neighbourWidth = (constraints.maxWidth - returnWidth - 16) / 2;
      bool fits(int delta) {
        if (neighbourWidth < 48) return false;
        final category =
            PlayerOptionsCategory.values[(_category.index + delta) %
                PlayerOptionsCategory.values.length];
        final painter = TextPainter(
          text: TextSpan(
            text: _strings.category(category),
            style: context.playerMenuTheme.meta,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 3,
        )..layout(maxWidth: (neighbourWidth - 48).clamp(0, double.infinity));
        final complete = !painter.didExceedMaxLines;
        painter.dispose();
        return complete;
      }

      Widget neighbours() => Row(
        children: [
          Expanded(child: _categoryStepButton(-1)),
          const SizedBox(width: 8),
          Expanded(child: _categoryStepButton(1)),
        ],
      );
      final back = returnAction == null
          ? null
          : SizedBox(width: returnWidth, child: returnAction);
      if (back != null && (!fits(-1) || !fits(1))) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            neighbours(),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft, child: back),
          ],
        );
      }
      return Row(
        children: [
          if (back != null) ...[back, const SizedBox(width: 8)],
          Expanded(child: neighbours()),
        ],
      );
    },
  );

  Widget _defaults({bool integrated = true}) => PlayerMenuSelectableRow(
    key: const ValueKey('options-defaults'),
    id: 'options-defaults',
    label: _strings.text('Rétablir cette catégorie', 'Reset this category'),
    leading: const Icon(Icons.restart_alt_rounded),
    labelMaxLines: 2,
    integrated: integrated,
    busy: _pending,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    onPressed: _enabled && _hasCategoryChanges ? _reset : null,
  );

  Widget _categories() => FocusScope(
    node: _categoryFocus,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = MediaQuery.sizeOf(context).aspectRatio > 1;
        final companion = PlayerCompanionScope.of(context);
        final columns = MediaQuery.textScalerOf(context).scale(1) >= 1.5
            ? 1
            : companion
            ? 2
            : wide
            ? 3
            : 1;
        final entries = <Widget>[
          for (final category in PlayerOptionsCategory.values)
            PlayerMenuSelectableRow(
              key: ValueKey('options-category-${category.name}'),
              id: 'options-category-${category.name}',
              label: _strings.category(category),
              minimumHeight: 56,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              leading: Icon(_icon(category), size: 24),
              selected: _category == category,
              onPressed: _pending ? null : () => _select(category),
            ),
          if (widget.onReturnToTitle != null)
            PlayerMenuSelectableRow(
              key: const ValueKey('options-return-title'),
              id: 'options-return-title',
              label: _strings.text('Retour au titre', 'Return to title'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              leading: const Icon(Icons.exit_to_app),
              onPressed: _pending ? null : widget.onReturnToTitle,
            ),
        ];
        return PlayerPagedList(
          key: const ValueKey('options-categories'),
          children: [
            for (var i = 0; i < entries.length; i += columns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: i + j < entries.length
                          ? entries[i + j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
          ],
        );
      },
    ),
  );

  Widget _settings(bool compact) => KeyedSubtree(
    key: const ValueKey('options-settings'),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final sideNavigation =
            constraints.maxHeight < 240 &&
            constraints.maxWidth >= 400 &&
            (MediaQuery.textScalerOf(context).scale(1) >= 1.5 ||
                (_category == PlayerOptionsCategory.controls && _showBindings));
        final companion = PlayerCompanionScope.of(context);
        final landscape = MediaQuery.sizeOf(context).aspectRatio > 1;
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = scale > 1.3
            ? 1
            : _category == PlayerOptionsCategory.audio
            ? (landscape && !companion ? 3 : 1)
            : _category == PlayerOptionsCategory.controls && _showBindings
            ? (landscape || companion ? 3 : 1)
            : _category == PlayerOptionsCategory.controls ||
                  _category == PlayerOptionsCategory.accessibility
            ? (companion
                  ? 2
                  : landscape
                  ? 4
                  : 1)
            : (landscape && !companion ? 3 : 1);
        final cellWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
        final rows = _categorySettings(
          _category == PlayerOptionsCategory.audio || cellWidth < 400,
        );
        return FocusScope(
          node: _settingsFocus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.navigation == null &&
                  _category == PlayerOptionsCategory.controls &&
                  widget.activeInputSource != PlayerInputSource.touch &&
                  MediaQuery.sizeOf(context).width >= 900 &&
                  MediaQuery.sizeOf(context).height >= 480)
                Align(
                  alignment: Alignment.centerRight,
                  child: _controlDeviceSwitch(),
                ),
              if (_pending)
                _status(
                  _strings.saving,
                  'options-saving',
                  Icons.hourglass_top_rounded,
                ),
              if (_failed)
                _status(
                  _saveError ?? _strings.error,
                  'options-save-error',
                  Icons.error_outline_rounded,
                ),
              if (_controlError case final error?)
                _status(
                  error,
                  'options-control-error',
                  Icons.info_outline_rounded,
                ),
              Expanded(
                child: PlayerPagedList(
                  key: ValueKey(
                    'options-settings-${_category.name}-${_showBindings ? 'bindings' : 'touch'}',
                  ),
                  sideNavigation: sideNavigation,
                  children: [
                    if (columns > 1)
                      for (var i = 0; i < rows.length; i += columns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (
                              var column = 0;
                              column < columns;
                              column++
                            ) ...[
                              if (column > 0)
                                SizedBox(width: companion ? 16 : 24),
                              Expanded(
                                child: i + column < rows.length
                                    ? rows[i + column]
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ],
                        )
                    else
                      for (var index = 0; index < rows.length; index++)
                        if (sideNavigation && rows[index] is _OptionSettingRow)
                          ...(rows[index] as _OptionSettingRow).atoms(context)
                        else
                          rows[index],
                    if (_category != PlayerOptionsCategory.controls ||
                        !_showBindings)
                      Padding(
                        padding: EdgeInsets.only(
                          top:
                              companion &&
                                  _category == PlayerOptionsCategory.audio &&
                                  scale <= 1.3
                              ? 0
                              : 8,
                        ),
                        child: _defaults(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _status(String message, String key, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      key: ValueKey(key),
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: context.playerMenuTheme.body)),
        ],
      ),
    ),
  );

  List<Widget> _categorySettings(bool compact) {
    final preferences = _confirmed;
    return switch (_category) {
      PlayerOptionsCategory.general => [
        _choiceRow(
          _strings.textSpeed,
          _strings.speed(preferences.dialogueTextSpeed),
          'text-speed',
          compact,
          () async {
            final value = await _choose(
              _strings.textSpeed,
              preferences.dialogueTextSpeed,
              {
                for (final value in RuntimeDialogueTextSpeed.values)
                  value: _strings.speed(value),
              },
              (value) => value.name,
              focusAfterClose: _choiceNode('text-speed'),
            );
            if (value != null) {
              await _save(
                _confirmed.copyWith(dialogueTextSpeed: value),
                focusAfterSave: _choiceNode('text-speed'),
              );
            }
          },
        ),
      ],
      PlayerOptionsCategory.display => [
        _choiceRow(
          _strings.menuEffects,
          _strings.effects(preferences.menuEffects),
          'menu-effects',
          compact,
          () async {
            final value = await _choose(
              _strings.menuEffects,
              preferences.menuEffects,
              {
                for (final value in RuntimePlayerMenuEffects.values)
                  value: _strings.effects(value),
              },
              (value) => value.name,
              focusAfterClose: _choiceNode('menu-effects'),
            );
            if (value != null) {
              await _save(
                _confirmed.copyWith(menuEffects: value),
                focusAfterSave: _choiceNode('menu-effects'),
              );
            }
          },
        ),
      ],
      PlayerOptionsCategory.audio => [
        _slider(
          _strings.master,
          'options-master-slider',
          preferences.audioMix.masterVolume,
          compact,
          (value, focusNode) => _save(
            _confirmed.copyWith(
              audioMix: RuntimeAudioMix(
                masterVolume: value,
                musicVolume: _confirmed.audioMix.musicVolume,
                effectsVolume: _confirmed.audioMix.effectsVolume,
              ),
            ),
            focusAfterSave: focusNode,
          ),
        ),
        _slider(
          _strings.music,
          'options-music-slider',
          preferences.audioMix.musicVolume,
          compact,
          (value, focusNode) => _save(
            _confirmed.copyWith(
              audioMix: RuntimeAudioMix(
                masterVolume: _confirmed.audioMix.masterVolume,
                musicVolume: value,
                effectsVolume: _confirmed.audioMix.effectsVolume,
              ),
            ),
            focusAfterSave: focusNode,
          ),
        ),
        _slider(
          _strings.soundEffects,
          'options-effects-slider',
          preferences.audioMix.effectsVolume,
          compact,
          (value, focusNode) => _save(
            _confirmed.copyWith(
              audioMix: RuntimeAudioMix(
                masterVolume: _confirmed.audioMix.masterVolume,
                musicVolume: _confirmed.audioMix.musicVolume,
                effectsVolume: value,
              ),
            ),
            focusAfterSave: focusNode,
          ),
        ),
      ],
      PlayerOptionsCategory.controls =>
        _showBindings
            ? _bindings(compact)
            : [
                _choiceRow(
                  _strings.touchRunMode,
                  _strings.runningMode(preferences.touchRunMode),
                  'touch-run-mode',
                  compact,
                  () async {
                    final value = await _choose(
                      _strings.touchRunMode,
                      preferences.touchRunMode,
                      {
                        for (final value in RuntimePlayerTouchRunMode.values)
                          value: _strings.runningMode(value),
                      },
                      (value) => value.name,
                      focusAfterClose: _choiceNode('touch-run-mode'),
                    );
                    if (value != null) {
                      await _save(
                        _confirmed.copyWith(touchRunMode: value),
                        focusAfterSave: _choiceNode('touch-run-mode'),
                      );
                    }
                  },
                ),
                _toggle(
                  _strings.leftHandedTouchControls,
                  'runtime-player-left-handed-touch-toggle',
                  preferences.leftHandedTouchControls,
                  compact,
                  (value) => _save(
                    _confirmed.copyWith(leftHandedTouchControls: value),
                  ),
                ),
                _toggle(
                  _strings.hints,
                  'runtime-player-input-hints-toggle',
                  preferences.showInputHints,
                  compact,
                  (value) => _save(_confirmed.copyWith(showInputHints: value)),
                ),
                _slider(
                  _strings.touchOpacity,
                  'touch-controls-opacity-slider',
                  preferences.touchControlsOpacity,
                  compact,
                  (value, focusNode) => _save(
                    _confirmed.copyWith(touchControlsOpacity: value),
                    focusAfterSave: focusNode,
                  ),
                  min: .3,
                  divisions: 14,
                ),
              ],
      PlayerOptionsCategory.language => [
        _choiceRow(
          _strings.interfaceLanguage,
          preferences.locale.toLowerCase().startsWith('fr')
              ? 'Français'
              : 'English',
          'locale',
          compact,
          () async {
            final value = await _choose(
              _strings.interfaceLanguage,
              preferences.locale,
              const {'fr': 'Français', 'en': 'English'},
              (value) => value,
              focusAfterClose: _choiceNode('locale'),
            );
            if (value != null) {
              await _save(
                _confirmed.copyWith(locale: value),
                focusAfterSave: _choiceNode('locale'),
              );
            }
          },
        ),
      ],
      PlayerOptionsCategory.accessibility => [
        _slider(
          _strings.textSize,
          'runtime-player-text-scale-slider',
          preferences.accessibility.textScale,
          compact,
          (value, focusNode) => _save(
            _confirmed.copyWith(
              accessibility: _confirmed.accessibility.copyWith(
                textScale: value,
              ),
            ),
            focusAfterSave: focusNode,
          ),
          min: .8,
          max: 1.6,
          divisions: 8,
        ),
        _toggle(
          _strings.reducedMotion,
          'runtime-player-reduced-motion-toggle',
          preferences.accessibility.reducedMotion,
          compact,
          (value) => _save(
            _confirmed.copyWith(
              accessibility: _confirmed.accessibility.copyWith(
                reducedMotion: value,
              ),
            ),
          ),
        ),
        _toggle(
          _strings.highContrast,
          'runtime-player-high-contrast-toggle',
          preferences.highContrast,
          compact,
          (value) => _save(_confirmed.copyWith(highContrast: value)),
        ),
        if (_hapticsSupported)
          _toggle(
            _strings.haptics,
            'runtime-player-haptics-toggle',
            preferences.accessibility.hapticsEnabled,
            compact,
            (value) => _save(
              _confirmed.copyWith(
                accessibility: _confirmed.accessibility.copyWith(
                  hapticsEnabled: value,
                ),
              ),
            ),
          ),
      ],
    };
  }

  Widget _row(
    String label,
    Widget control,
    bool compact, {
    int labelFlex = 6,
    String? valueLabel,
    Key? key,
  }) => _OptionSettingRow(
    key: key,
    label: label,
    control: control,
    compact: compact,
    labelFlex: labelFlex,
    valueLabel: valueLabel,
    dense:
        _category == PlayerOptionsCategory.controls &&
        MediaQuery.sizeOf(context).height <= 480 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3,
  );

  Widget _choiceRow(
    String label,
    String value,
    String id,
    bool compact,
    VoidCallback onPressed, {
    bool? enabled,
  }) => _row(
    label,
    PlayerMenuSelectableRow(
      key: ValueKey('options-$id-choice'),
      id: 'options-$id-choice',
      focusNode: _choiceNode(id),
      showFocusHighlight:
          widget.activeInputSource == PlayerInputSource.keyboard ||
          widget.activeInputSource == PlayerInputSource.controller,
      label: value,
      semanticValue: label,
      reserveFocusMarker: false,
      trailing: const Icon(Icons.expand_more_rounded),
      trailingWidth: 24,
      labelMaxLines: 3,
      labelStyle: context.playerMenuTheme.label.copyWith(fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onPressed: (enabled ?? _enabled) ? onPressed : null,
    ),
    compact,
  );

  Widget _toggle(
    String label,
    String key,
    bool value,
    bool compact,
    ValueChanged<bool> onChanged,
  ) => _row(
    label,
    Align(
      alignment: compact ? Alignment.centerLeft : Alignment.centerRight,
      child: Semantics(
        label: label,
        child: Switch.adaptive(
          key: ValueKey(key),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          value: value,
          onChanged: _enabled ? onChanged : null,
        ),
      ),
    ),
    compact,
  );

  Widget _slider(
    String label,
    String key,
    double value,
    bool compact,
    void Function(double value, FocusNode focusNode) onChanged, {
    double min = 0,
    double max = 1,
    int divisions = 20,
  }) {
    final draft = _drafts[key] ?? value;
    final focusNode = _sliderFocus.putIfAbsent(
      key,
      () => FocusNode(debugLabel: label),
    );
    final compactCompanion =
        PlayerCompanionScope.of(context) &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    void step(int direction) {
      if (!_enabled) return;
      final next = (draft + direction * (max - min) / divisions).clamp(
        min,
        max,
      );
      if (next == draft) return;
      onChanged(double.parse(next.toStringAsFixed(2)), focusNode);
    }

    return _row(
      label,
      Actions(
        actions: {
          RuntimePlayerLogicalIntent:
              CallbackAction<RuntimePlayerLogicalIntent>(
                onInvoke: (intent) {
                  if (_category == PlayerOptionsCategory.audio &&
                      (intent.action == PlayerInputAction.up ||
                          intent.action == PlayerInputAction.down)) {
                    const channels = [
                      'options-master-slider',
                      'options-music-slider',
                      'options-effects-slider',
                    ];
                    final index = channels.indexOf(key);
                    final next =
                        index +
                        (intent.action == PlayerInputAction.down ? 1 : -1);
                    if (index >= 0 && next >= 0 && next < channels.length) {
                      final focus = _sliderFocus[channels[next]];
                      if (focus?.canRequestFocus == true) focus!.requestFocus();
                    }
                    return null;
                  }
                  if (intent.action == PlayerInputAction.left ||
                      intent.action == PlayerInputAction.right) {
                    step(intent.action == PlayerInputAction.left ? -1 : 1);
                    return null;
                  }
                  return _input(intent);
                },
              ),
        },
        child: Semantics(
          label: label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: compactCompanion ? 48 : null,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: compactCompanion
                        ? const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                            disabledThumbRadius: 8,
                          )
                        : SliderTheme.of(context).thumbShape,
                    overlayShape: compactCompanion
                        ? const RoundSliderOverlayShape(overlayRadius: 16)
                        : SliderTheme.of(context).overlayShape,
                    trackHeight: compactCompanion
                        ? 4
                        : SliderTheme.of(context).trackHeight,
                    activeTrackColor: context.playerMenuTheme.accent,
                    thumbColor: context.playerMenuTheme.text,
                    inactiveTrackColor: context.playerMenuTheme.border,
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    key: ValueKey(key),
                    focusNode: focusNode,
                    onChangeStart: _enabled
                        ? (_) {
                            RuntimePlayerLocalActionNotification().dispatch(
                              context,
                            );
                            focusNode.requestFocus();
                          }
                        : null,
                    value: draft.clamp(min, max),
                    min: min,
                    max: max,
                    divisions: divisions,
                    semanticFormatterCallback: (value) =>
                        '${(value * 100).round()} %',
                    onChanged: _enabled
                        ? (value) => setState(() => _drafts[key] = value)
                        : null,
                    onChangeEnd: _enabled
                        ? (value) => onChanged(value, focusNode)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      true,
      labelFlex: 7,
      valueLabel: '${(draft * 100).round()} %',
      key: ValueKey('$key-setting'),
    );
  }

  List<Widget> _bindings(bool compact) {
    if (widget.activeInputSource == PlayerInputSource.touch) return const [];
    final strings = PlayerControlStrings.of(context);
    final device = widget.activeInputSource == PlayerInputSource.controller
        ? PlayerControlDevice.gamepad
        : PlayerControlDevice.keyboard;
    return [
      for (final control in RuntimeInputControl.values)
        PlayerMenuSelectableRow(
          key: ValueKey('options-binding-${control.name}-choice'),
          id: 'options-binding-${control.name}-choice',
          focusNode: _choiceNode('binding-${control.name}'),
          label: strings.control(control),
          labelMaxLines: null,
          labelStyle: context.playerMenuTheme.label.copyWith(fontSize: 14),
          minimumHeight: 48,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          trailing: Text(
            _profile.glyphFor(device, control),
            style: context.playerMenuTheme.numbers.copyWith(fontSize: 14),
            maxLines: 1,
            softWrap: false,
          ),
          trailingWidth: MediaQuery.textScalerOf(context).scale(64),
          semanticValue: _profile.glyphFor(device, control),
          onPressed: !_pending && widget.onControlProfileChanged != null
              ? () async {
                  final inputs = device == PlayerControlDevice.keyboard
                      ? playerKeyboardInputs.keys
                      : playerGamepadInputs;
                  final value = await _choose(
                    strings.control(control),
                    _profile.bindingFor(device, control),
                    {
                      for (final input in inputs)
                        input: PlayerControlProfile.glyphForInput(input),
                    },
                    (value) => value,
                    focusAfterClose: _choiceNode('binding-${control.name}'),
                  );
                  if (value == null || !mounted) return;
                  final result = _profile.rebind(
                    device: device,
                    control: control,
                    inputId: value,
                  );
                  if (result.hasConflict) {
                    setState(() => _controlError = strings.conflict);
                    return;
                  }
                  await _saveProfile(
                    result.profile,
                    focusAfterSave: _choiceNode('binding-${control.name}'),
                  );
                }
              : null,
        ),
      if (widget.onControlProfileChanged != null)
        PlayerActionButton(
          key: const ValueKey('options-controls-reset'),
          label: '${strings.reset} · ${strings.device(device)}',
          icon: Icons.restart_alt_rounded,
          labelMaxLines: 3,
          secondary: true,
          onPressed: _pending
              ? null
              : () async {
                  if (await _confirm(
                    _strings.resetTitle(PlayerOptionsCategory.controls),
                    _strings.text(
                      'Seules les touches ${strings.device(device)} seront rétablies. Les autres réglages seront conservés.',
                      'Only ${strings.device(device)} bindings will be reset. Other settings will be kept.',
                    ),
                  )) {
                    await _saveProfile(_profile.resetDevice(device));
                  }
                },
        ),
    ];
  }

  Future<T?> _choose<T>(
    String title,
    T current,
    Map<T, String> values,
    String Function(T) id, {
    FocusNode? focusAfterClose,
  }) async {
    if (!mounted || _pending || _dialogRoute != null) return null;
    RuntimePlayerLocalActionNotification().dispatch(context);
    final selected = await _showDialog<T>(
      builder: (dialogContext) => _dialog(
        title: title,
        children: [
          for (final entry in values.entries)
            PlayerMenuSelectableRow(
              key: ValueKey('options-choice-${id(entry.key)}'),
              id: 'options-choice-${id(entry.key)}',
              label: entry.value,
              selected: entry.key == current,
              onPressed: () => Navigator.of(dialogContext).pop(entry.key),
            ),
        ],
        actions: [
          PlayerActionButton(
            key: const ValueKey('options-choice-back'),
            autofocus: true,
            label: _strings.text('Retour', 'Back'),
            icon: Icons.arrow_back,
            secondary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
    _restoreChoiceFocus(focusAfterClose);
    return selected == current ? null : selected;
  }

  Future<T?> _showDialog<T>({required WidgetBuilder builder}) async {
    if (!mounted || _dialogRoute != null) return null;
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<T>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (context) =>
          mounted ? builder(context) : const SizedBox.shrink(),
    );
    _dialogRoute = route;
    final result = await navigator.push(route);
    if (identical(_dialogRoute, route)) _dialogRoute = null;
    return mounted ? result : null;
  }

  Widget _dialog({
    required String title,
    required List<Widget> children,
    required List<Widget> actions,
  }) => MediaQuery(
    data: MediaQuery.of(context),
    child: Localizations.override(
      context: context,
      locale: Localizations.localeOf(context),
      child: RuntimePlayerActions(
        onBack: () => Navigator.of(context, rootNavigator: true).pop(),
        onMenu: () {},
        onInputSourceChanged: (_) {},
        child: RuntimePlayerInputBindings(
          controlProfile: _profile,
          hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
          child: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.options,
            opaque: context.playerMenuTheme.opaque,
            child: Dialog(
              backgroundColor: context.playerMenuTheme.base,
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: PlayerMenuPanel(
                  child: _OptionsDialogBody(
                    title: title,
                    actions: actions,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<bool> _confirm(String title, String message) async {
    RuntimePlayerLocalActionNotification().dispatch(context);
    return await _showDialog<bool>(
          builder: (dialogContext) => _dialog(
            title: title,
            children: [Text(message)],
            actions: [
              PlayerActionButton(
                key: const ValueKey('options-reset-cancel'),
                label: _strings.cancel,
                icon: Icons.close_rounded,
                autofocus: true,
                secondary: true,
                onPressed: () {
                  RuntimePlayerLocalActionNotification().dispatch(context);
                  Navigator.of(dialogContext).pop(false);
                },
              ),
              const SizedBox(height: 12),
              PlayerActionButton(
                key: const ValueKey('options-reset-confirm'),
                label: _strings.restore,
                icon: Icons.restart_alt_rounded,
                onPressed: () {
                  RuntimePlayerLocalActionNotification().dispatch(context);
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          ),
        ) ??
        false;
  }

  bool get _hasCategoryChanges {
    final value = _confirmed;
    final defaults = widget.defaultPreferences;
    return switch (_category) {
      PlayerOptionsCategory.general =>
        value.dialogueTextSpeed != defaults.dialogueTextSpeed,
      PlayerOptionsCategory.display =>
        value.menuEffects != defaults.menuEffects,
      PlayerOptionsCategory.audio =>
        value.audioMix.masterVolume != defaults.audioMix.masterVolume ||
            value.audioMix.musicVolume != defaults.audioMix.musicVolume ||
            value.audioMix.effectsVolume != defaults.audioMix.effectsVolume,
      PlayerOptionsCategory.controls =>
        value.touchRunMode != defaults.touchRunMode ||
            value.leftHandedTouchControls != defaults.leftHandedTouchControls ||
            value.showInputHints != defaults.showInputHints ||
            value.touchControlsOpacity != defaults.touchControlsOpacity,
      PlayerOptionsCategory.language => value.locale != defaults.locale,
      PlayerOptionsCategory.accessibility =>
        value.highContrast != defaults.highContrast ||
            value.accessibility.reducedMotion !=
                defaults.accessibility.reducedMotion ||
            value.accessibility.textScale != defaults.accessibility.textScale ||
            _hapticsSupported &&
                value.accessibility.hapticsEnabled !=
                    defaults.accessibility.hapticsEnabled,
    };
  }

  Future<void> _reset() async {
    final category = _category;
    if (!await _confirm(
          _strings.resetTitle(category),
          _strings.resetMessage(category),
        ) ||
        !mounted) {
      return;
    }
    final defaults = widget.defaultPreferences;
    await _save(switch (category) {
      PlayerOptionsCategory.general => _confirmed.copyWith(
        dialogueTextSpeed: defaults.dialogueTextSpeed,
      ),
      PlayerOptionsCategory.display => _confirmed.copyWith(
        menuEffects: defaults.menuEffects,
      ),
      PlayerOptionsCategory.audio => _confirmed.copyWith(
        audioMix: defaults.audioMix,
      ),
      PlayerOptionsCategory.controls => _confirmed.copyWith(
        touchRunMode: defaults.touchRunMode,
        leftHandedTouchControls: defaults.leftHandedTouchControls,
        showInputHints: defaults.showInputHints,
        touchControlsOpacity: defaults.touchControlsOpacity,
      ),
      PlayerOptionsCategory.language => _confirmed.copyWith(
        locale: defaults.locale,
      ),
      PlayerOptionsCategory.accessibility => _confirmed.copyWith(
        highContrast: defaults.highContrast,
        accessibility: defaults.accessibility.copyWith(
          hapticsEnabled: _hapticsSupported
              ? defaults.accessibility.hapticsEnabled
              : _confirmed.accessibility.hapticsEnabled,
        ),
      ),
    });
  }

  IconData _icon(PlayerOptionsCategory category) => switch (category) {
    PlayerOptionsCategory.general => Icons.tune_rounded,
    PlayerOptionsCategory.display => Icons.desktop_windows_rounded,
    PlayerOptionsCategory.audio => Icons.volume_up_rounded,
    PlayerOptionsCategory.controls => Icons.sports_esports_rounded,
    PlayerOptionsCategory.language => Icons.language_rounded,
    PlayerOptionsCategory.accessibility => Icons.accessibility_new_rounded,
  };
}

class _OptionsDialogBody extends StatefulWidget {
  const _OptionsDialogBody({
    required this.title,
    required this.children,
    required this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  State<_OptionsDialogBody> createState() => _OptionsDialogBodyState();
}

class _OptionsDialogBodyState extends State<_OptionsDialogBody> {
  double? _contentHeight;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Flexible(
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: _contentHeight == null
                ? constraints.maxHeight
                : _contentHeight!.clamp(0, constraints.maxHeight),
            child: PlayerPagedList(
              onContentHeightChanged: (height) {
                if (mounted &&
                    (_contentHeight == null ||
                        (_contentHeight! - height).abs() > .5)) {
                  setState(() => _contentHeight = height);
                }
              },
              children: [
                Text(widget.title, style: context.playerMenuTheme.subtitle),
                ...widget.children,
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      ...widget.actions,
    ],
  );
}

class _OptionSettingRow extends StatelessWidget {
  const _OptionSettingRow({
    super.key,
    required this.label,
    required this.control,
    required this.compact,
    required this.labelFlex,
    this.valueLabel,
    this.dense = false,
  });

  final String label;
  final Widget control;
  final bool compact;
  final int labelFlex;
  final String? valueLabel;
  final bool dense;

  List<Widget> atoms(BuildContext context) => [
    if (valueLabel == null)
      Text(
        label,
        style: context.playerMenuTheme.label.copyWith(
          fontSize: dense ? 14 : null,
        ),
      )
    else
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.playerMenuTheme.label.copyWith(
                fontSize: dense ? 14 : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            valueLabel!,
            style: context.playerMenuTheme.numbers.copyWith(
              fontSize: dense ? 14 : null,
            ),
          ),
        ],
      ),
    control,
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      minHeight:
          valueLabel != null &&
              PlayerCompanionScope.of(context) &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3
          ? 64
          : 72,
    ),
    child: valueLabel != null
        ? LayoutBuilder(
            builder: (context, constraints) {
              final compactCompanion =
                  PlayerCompanionScope.of(context) &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.3;
              final heading = Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.playerMenuTheme.label.copyWith(
                        fontSize: compactCompanion
                            ? 15
                            : dense
                            ? 14
                            : null,
                        height: compactCompanion ? 1.3 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    valueLabel!,
                    style: context.playerMenuTheme.numbers.copyWith(
                      fontSize: compactCompanion
                          ? 18
                          : dense
                          ? 14
                          : null,
                      height: compactCompanion ? 1.2 : null,
                    ),
                  ),
                ],
              );
              if (compactCompanion) {
                return SizedBox(
                  height: 64,
                  child: Stack(
                    children: [
                      heading,
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SizedBox(height: 48, child: control),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [heading, control],
              );
            },
          )
        : compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: context.playerMenuTheme.label.copyWith(
                  fontSize: dense ? 14 : null,
                ),
              ),
              const SizedBox(height: 8),
              control,
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: labelFlex,
                child: Text(
                  label,
                  style: context.playerMenuTheme.label.copyWith(
                    fontSize: dense ? 14 : null,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: control),
            ],
          ),
  );
}
