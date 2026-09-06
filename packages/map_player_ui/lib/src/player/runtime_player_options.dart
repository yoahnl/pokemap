import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
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

class RuntimePlayerOptions extends StatefulWidget {
  const RuntimePlayerOptions({
    super.key,
    required this.preferences,
    this.defaultPreferences = const PlayerPreferencesSnapshot(
        locale: 'fr', accessibility: GameSessionAccessibilityOptions()),
    this.onChanged,
    this.onReturnToTitle,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
    this.onControlProfileChanged,
    this.activeInputSource = PlayerInputSource.keyboard,
  });

  final PlayerPreferencesSnapshot preferences;
  final PlayerPreferencesSnapshot defaultPreferences;
  final FutureOr<void> Function(PlayerPreferencesSnapshot)? onChanged;
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
  final _choiceFocus = FocusNode(debugLabel: 'Selected option');
  final _categoryScroll = ScrollController();
  final _settingsScroll = ScrollController();
  final _categoryFocus = FocusScopeNode(debugLabel: 'Options categories');
  final _settingsFocus = FocusScopeNode(debugLabel: 'Options settings');
  PlayerOptionsCategory _category = PlayerOptionsCategory.general;
  bool _showCategories = false;
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
  void didUpdateWidget(RuntimePlayerOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final route = _dialogRoute;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
    for (final node in _sliderFocus.values) {
      node.dispose();
    }
    _choiceFocus.dispose();
    _categoryScroll.dispose();
    _settingsScroll.dispose();
    _categoryFocus.dispose();
    _settingsFocus.dispose();
    super.dispose();
  }

  Future<void> _save(PlayerPreferencesSnapshot next) async {
    if (!mounted || !_enabled) return;
    final previousWidget = widget.preferences;
    final previousFocus = FocusManager.instance.primaryFocus;
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
          _saveError =
              error is RuntimePlayerOptionsFailure ? error.safeMessage : null;
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
              previousFocus?.context != null &&
              previousFocus!.canRequestFocus) {
            previousFocus.requestFocus();
          }
        });
      }
    }
  }

  Future<void> _saveProfile(PlayerControlProfile next) async {
    if (!mounted || _pending || widget.onControlProfileChanged == null) return;
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
          _saveError =
              error is RuntimePlayerOptionsFailure ? error.safeMessage : null;
        });
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  void _select(PlayerOptionsCategory category) {
    if (_pending) return;
    setState(() {
      _category = category;
      _showCategories = false;
      _drafts.clear();
    });
    if (_settingsScroll.hasClients) _settingsScroll.jumpTo(0);
  }

  Object? _input(RuntimePlayerLogicalIntent intent) {
    if (_pending && intent.action != PlayerInputAction.back) return null;
    if (intent.action == PlayerInputAction.left && _settingsFocus.hasFocus) {
      _categoryFocus.requestFocus();
      return null;
    }
    if (intent.action == PlayerInputAction.right && _categoryFocus.hasFocus) {
      _settingsFocus.requestFocus();
      return null;
    }
    if (intent.action == PlayerInputAction.back && _showCategories) {
      setState(() => _showCategories = false);
      return null;
    }
    return Actions.maybeInvoke(context, intent);
  }

  @override
  Widget build(BuildContext context) => RuntimePlayerInputBindings(
        controlProfile: _profile,
        hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
        child: _buildOptions(context),
      );

  Widget _buildOptions(BuildContext context) => Actions(
        actions: {
          RuntimePlayerLogicalIntent:
              CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: _input)
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 900 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.8;
          final short = compact && constraints.maxHeight < 280;
          return Column(
            key: const ValueKey('runtime-player-options'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (short) ...[
                Row(children: [
                  Expanded(child: _categoryPicker()),
                  const SizedBox(width: 12),
                  Expanded(child: _defaults()),
                ]),
                const SizedBox(height: 12),
              ] else if (compact && !_showCategories) ...[
                _categoryPicker(),
                const SizedBox(height: 12),
              ],
              Expanded(
                  child: compact
                      ? (_showCategories ? _categories() : _settings(compact))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              SizedBox(width: 320, child: _categories()),
                              const SizedBox(width: 24),
                              Expanded(child: _settings(compact)),
                            ])),
              if (!short) ...[
                const SizedBox(height: 12),
                _defaults(),
              ],
            ],
          );
        }),
      );

  Widget _categoryPicker() => PlayerActionButton(
        key: const ValueKey('options-category-picker'),
        label: _strings.category(_category),
        labelMaxLines: 3,
        expandContent: true,
        icon: Icons.menu_rounded,
        secondary: true,
        onPressed: _pending
            ? null
            : () => setState(() => _showCategories = !_showCategories),
      );

  Widget _defaults() => PlayerActionButton(
        key: const ValueKey('options-defaults'),
        label: _strings.defaults,
        icon: Icons.restart_alt_rounded,
        labelMaxLines: 2,
        secondary: true,
        onPressed: _enabled ? _reset : null,
      );

  Widget _categories() => FocusScope(
        node: _categoryFocus,
        child: SingleChildScrollView(
          key: const ValueKey('options-categories'),
          controller: _categoryScroll,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final category in PlayerOptionsCategory.values) ...[
              if (category != PlayerOptionsCategory.general)
                const SizedBox(height: 12),
              PlayerMenuSelectableRow(
                key: ValueKey('options-category-${category.name}'),
                id: 'options-category-${category.name}',
                label: _strings.category(category),
                minimumHeight: 64,
                leading: Icon(_icon(category), size: 32),
                selected: _category == category,
                onPressed: _pending ? null : () => _select(category),
              ),
            ],
            if (widget.onReturnToTitle != null) ...[
              const SizedBox(height: 24),
              PlayerMenuSelectableRow(
                key: const ValueKey('options-return-title'),
                id: 'options-return-title',
                label: _strings.returnToTitle,
                leading: const Icon(Icons.exit_to_app_rounded, size: 32),
                minimumHeight: 64,
                onPressed: _pending ? null : widget.onReturnToTitle,
              ),
            ],
          ]),
        ),
      );

  Widget _settings(bool compact) => PlayerMenuPanel(
        key: const ValueKey('options-settings'),
        padding: const EdgeInsets.all(24),
        child: FocusScope(
          node: _settingsFocus,
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                    key: const ValueKey('options-settings-scroll'),
                    controller: _settingsScroll,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: compact ? 0 : constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(_strings.category(_category),
                                    style: context.playerMenuTheme.subtitle),
                                const SizedBox(height: 16),
                                if (_pending)
                                  _status(_strings.saving, 'options-saving',
                                      Icons.hourglass_top_rounded),
                                if (_failed)
                                  _status(
                                      _saveError ?? _strings.error,
                                      'options-save-error',
                                      Icons.error_outline_rounded),
                                if (_controlError case final error?)
                                  _status(error, 'options-control-error',
                                      Icons.info_outline_rounded),
                                for (final setting
                                    in _categorySettings(compact)) ...[
                                  setting,
                                  const SizedBox(height: 12)
                                ],
                                const SizedBox(height: 12),
                              ]),
                          PlayerMenuPanel(
                            key: const ValueKey('options-help'),
                            padding: const EdgeInsets.all(16),
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minHeight: compact ? 0 : 64),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_strings.help(_category),
                                        style: context.playerMenuTheme.meta),
                                    const SizedBox(height: 8),
                                    Text(_strings.scope,
                                        style: context.playerMenuTheme.meta),
                                  ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
        ),
      );

  Widget _status(String message, String key, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          key: ValueKey(key),
          liveRegion: true,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: context.playerMenuTheme.body)),
          ]),
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
              compact, () async {
            final value = await _choose(
                _strings.textSpeed,
                preferences.dialogueTextSpeed,
                {
                  for (final value in RuntimeDialogueTextSpeed.values)
                    value: _strings.speed(value)
                },
                (value) => value.name);
            if (value != null) {
              await _save(_confirmed.copyWith(dialogueTextSpeed: value));
            }
          }),
        ],
      PlayerOptionsCategory.display => [
          _choiceRow(
              _strings.menuEffects,
              _strings.effects(preferences.menuEffects),
              'menu-effects',
              compact, () async {
            final value = await _choose(
                _strings.menuEffects,
                preferences.menuEffects,
                {
                  for (final value in RuntimePlayerMenuEffects.values)
                    value: _strings.effects(value)
                },
                (value) => value.name);
            if (value != null) {
              await _save(_confirmed.copyWith(menuEffects: value));
            }
          }),
        ],
      PlayerOptionsCategory.audio => [
          _slider(
              _strings.master,
              'options-master-slider',
              preferences.audioMix.masterVolume,
              compact,
              (value) => _save(_confirmed.copyWith(
                  audioMix: RuntimeAudioMix(
                      masterVolume: value,
                      musicVolume: _confirmed.audioMix.musicVolume,
                      effectsVolume: _confirmed.audioMix.effectsVolume)))),
          _slider(
              _strings.music,
              'options-music-slider',
              preferences.audioMix.musicVolume,
              compact,
              (value) => _save(_confirmed.copyWith(
                  audioMix: RuntimeAudioMix(
                      masterVolume: _confirmed.audioMix.masterVolume,
                      musicVolume: value,
                      effectsVolume: _confirmed.audioMix.effectsVolume)))),
          _slider(
              _strings.soundEffects,
              'options-effects-slider',
              preferences.audioMix.effectsVolume,
              compact,
              (value) => _save(_confirmed.copyWith(
                  audioMix: RuntimeAudioMix(
                      masterVolume: _confirmed.audioMix.masterVolume,
                      musicVolume: _confirmed.audioMix.musicVolume,
                      effectsVolume: value)))),
        ],
      PlayerOptionsCategory.controls => [
          _toggle(
              _strings.hints,
              'runtime-player-input-hints-toggle',
              preferences.showInputHints,
              compact,
              (value) => _save(_confirmed.copyWith(showInputHints: value))),
          _slider(
              _strings.touchOpacity,
              'touch-controls-opacity-slider',
              preferences.touchControlsOpacity,
              compact,
              (value) =>
                  _save(_confirmed.copyWith(touchControlsOpacity: value)),
              min: .3,
              divisions: 14),
          ..._bindings(compact),
        ],
      PlayerOptionsCategory.language => [
          _choiceRow(
              _strings.interfaceLanguage,
              preferences.locale.toLowerCase().startsWith('fr')
                  ? 'Français'
                  : 'English',
              'locale',
              compact, () async {
            final value = await _choose(
                _strings.interfaceLanguage,
                preferences.locale,
                const {'fr': 'Français', 'en': 'English'},
                (value) => value);
            if (value != null) await _save(_confirmed.copyWith(locale: value));
          }),
        ],
      PlayerOptionsCategory.accessibility => [
          _slider(
              _strings.textSize,
              'runtime-player-text-scale-slider',
              preferences.accessibility.textScale,
              compact,
              (value) => _save(_confirmed.copyWith(
                  accessibility:
                      _confirmed.accessibility.copyWith(textScale: value))),
              min: .8,
              max: 1.6,
              divisions: 8),
          _toggle(
              _strings.reducedMotion,
              'runtime-player-reduced-motion-toggle',
              preferences.accessibility.reducedMotion,
              compact,
              (value) => _save(_confirmed.copyWith(
                  accessibility: _confirmed.accessibility
                      .copyWith(reducedMotion: value)))),
          _toggle(
              _strings.highContrast,
              'runtime-player-high-contrast-toggle',
              preferences.highContrast,
              compact,
              (value) => _save(_confirmed.copyWith(highContrast: value))),
          if (_hapticsSupported)
            _toggle(
                _strings.haptics,
                'runtime-player-haptics-toggle',
                preferences.accessibility.hapticsEnabled,
                compact,
                (value) => _save(_confirmed.copyWith(
                    accessibility: _confirmed.accessibility
                        .copyWith(hapticsEnabled: value)))),
        ],
    };
  }

  Widget _row(String label, Widget control, bool compact) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: compact
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(label, style: context.playerMenuTheme.label),
                const SizedBox(height: 8),
                control,
              ])
            : Row(children: [
                Expanded(
                    flex: 6,
                    child: Text(label, style: context.playerMenuTheme.label)),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: control),
              ]),
      );

  Widget _choiceRow(String label, String value, String id, bool compact,
          VoidCallback onPressed,
          {bool? enabled}) =>
      _row(
          label,
          PlayerActionButton(
            key: ValueKey('options-$id-choice'),
            label: value,
            icon: Icons.unfold_more_rounded,
            secondary: true,
            labelMaxLines: 3,
            expandContent: true,
            onPressed: (enabled ?? _enabled) ? onPressed : null,
          ),
          compact);

  Widget _toggle(String label, String key, bool value, bool compact,
          ValueChanged<bool> onChanged) =>
      _row(
          label,
          Align(
              alignment: compact ? Alignment.centerLeft : Alignment.centerRight,
              child: Semantics(
                  label: label,
                  child: Switch.adaptive(
                    key: ValueKey(key),
                    value: value,
                    onChanged: _enabled ? onChanged : null,
                  ))),
          compact);

  Widget _slider(String label, String key, double value, bool compact,
      ValueChanged<double> onChanged,
      {double min = 0, double max = 1, int divisions = 20}) {
    final draft = _drafts[key] ?? value;
    void step(int direction) {
      if (!_enabled) return;
      final next =
          (draft + direction * (max - min) / divisions).clamp(min, max);
      if (next == draft) return;
      onChanged(double.parse(next.toStringAsFixed(2)));
    }

    return _row(
        label,
        Actions(
          actions: {
            RuntimePlayerLogicalIntent:
                CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: (intent) {
              if (intent.action == PlayerInputAction.left ||
                  intent.action == PlayerInputAction.right) {
                step(intent.action == PlayerInputAction.left ? -1 : 1);
                return null;
              }
              return _input(intent);
            })
          },
          child: Semantics(
              label: label,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${(draft * 100).round()} %',
                        textAlign: TextAlign.end,
                        style: context.playerMenuTheme.label),
                    SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: context.playerMenuTheme.accent,
                          thumbColor: context.playerMenuTheme.text,
                          inactiveTrackColor: context.playerMenuTheme.border,
                          showValueIndicator: ShowValueIndicator.never,
                        ),
                        child: Slider(
                          key: ValueKey(key),
                          focusNode: _sliderFocus.putIfAbsent(
                              key, () => FocusNode(debugLabel: label)),
                          onChangeStart: _enabled
                              ? (_) => _sliderFocus[key]!.requestFocus()
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
                          onChangeEnd: _enabled ? onChanged : null,
                        )),
                  ])),
        ),
        compact);
  }

  List<Widget> _bindings(bool compact) {
    final strings = PlayerControlStrings.of(context);
    final device = switch (widget.activeInputSource) {
      PlayerInputSource.controller => PlayerControlDevice.gamepad,
      PlayerInputSource.touch => PlayerControlDevice.touch,
      _ => PlayerControlDevice.keyboard,
    };
    return [
      Text(strings.device(device), style: context.playerMenuTheme.label),
      if (device == PlayerControlDevice.touch &&
          widget.onControlProfileChanged != null)
        PlayerActionButton(
          key: const ValueKey('options-controls-touch-swap'),
          label: strings.swapTouch,
          icon: Icons.swap_horiz,
          secondary: true,
          onPressed: _pending
              ? null
              : () => _saveProfile(_profile.swapBindings(
                    device: device,
                    first: RuntimeInputControl.primary,
                    second: RuntimeInputControl.secondary,
                  )),
        ),
      for (final control in RuntimeInputControl.values)
        _choiceRow(strings.control(control), _profile.glyphFor(device, control),
            'binding-${control.name}', compact, () async {
          final inputs = switch (device) {
            PlayerControlDevice.keyboard => playerKeyboardInputs.keys,
            PlayerControlDevice.gamepad => playerGamepadInputs,
            PlayerControlDevice.touch => playerTouchInputs,
          };
          final value = await _choose(
              strings.control(control),
              _profile.bindingFor(device, control),
              {
                for (final input in inputs)
                  input: PlayerControlProfile.glyphForInput(input)
              },
              (value) => value);
          if (value == null || !mounted) return;
          final result =
              _profile.rebind(device: device, control: control, inputId: value);
          if (result.hasConflict) {
            setState(() => _controlError = strings.conflict);
            return;
          }
          await _saveProfile(result.profile);
        },
            enabled: device != PlayerControlDevice.touch &&
                !_pending &&
                widget.onControlProfileChanged != null),
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
                          'Only ${strings.device(device)} bindings will be reset. Other settings will be kept.'))) {
                    await _saveProfile(_profile.resetDevice(device));
                  }
                },
        ),
    ];
  }

  Future<T?> _choose<T>(String title, T current, Map<T, String> values,
      String Function(T) id) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _choiceFocus.context != null) _choiceFocus.requestFocus();
    });
    return _showDialog<T>(
        builder: (dialogContext) => _dialog(
              title: title,
              children: [
                for (final entry in values.entries) ...[
                  PlayerMenuSelectableRow(
                    key: ValueKey('options-choice-${id(entry.key)}'),
                    id: 'options-choice-${id(entry.key)}',
                    focusNode: current == entry.key ? _choiceFocus : null,
                    label: entry.value,
                    selected: current == entry.key,
                    minimumHeight: 64,
                    onPressed: () => Navigator.of(dialogContext).pop(entry.key),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              actions: [
                PlayerActionButton(
                  key: const ValueKey('options-choice-back'),
                  label: _strings.back,
                  icon: Icons.arrow_back_rounded,
                  secondary: true,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                )
              ],
            ));
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

  Widget _dialog(
          {required String title,
          required List<Widget> children,
          required List<Widget> actions}) =>
      MediaQuery(
          data: MediaQuery.of(context),
          child: Localizations.override(
              context: context,
              locale: Localizations.localeOf(context),
              child: RuntimePlayerActions(
                  onBack: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
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
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                    Flexible(
                                        child: SingleChildScrollView(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                          Text(title,
                                              style: context
                                                  .playerMenuTheme.subtitle),
                                          const SizedBox(height: 20),
                                          ...children,
                                        ]))),
                                    const SizedBox(height: 12),
                                    ...actions,
                                  ])),
                            ),
                          ))))));

  Future<bool> _confirm(String title, String message) async =>
      await _showDialog<bool>(
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
                      onPressed: () => Navigator.of(dialogContext).pop(false)),
                  const SizedBox(height: 12),
                  PlayerActionButton(
                      key: const ValueKey('options-reset-confirm'),
                      label: _strings.restore,
                      icon: Icons.restart_alt_rounded,
                      onPressed: () => Navigator.of(dialogContext).pop(true)),
                ],
              )) ??
      false;

  Future<void> _reset() async {
    final category = _category;
    if (!await _confirm(
            _strings.resetTitle(category), _strings.resetMessage(category)) ||
        !mounted) {
      return;
    }
    final defaults = widget.defaultPreferences;
    await _save(switch (category) {
      PlayerOptionsCategory.general =>
        _confirmed.copyWith(dialogueTextSpeed: defaults.dialogueTextSpeed),
      PlayerOptionsCategory.display =>
        _confirmed.copyWith(menuEffects: defaults.menuEffects),
      PlayerOptionsCategory.audio =>
        _confirmed.copyWith(audioMix: defaults.audioMix),
      PlayerOptionsCategory.controls => _confirmed.copyWith(
          showInputHints: defaults.showInputHints,
          touchControlsOpacity: defaults.touchControlsOpacity),
      PlayerOptionsCategory.language =>
        _confirmed.copyWith(locale: defaults.locale),
      PlayerOptionsCategory.accessibility => _confirmed.copyWith(
          highContrast: defaults.highContrast,
          accessibility: defaults.accessibility.copyWith(
              hapticsEnabled: _hapticsSupported
                  ? defaults.accessibility.hapticsEnabled
                  : _confirmed.accessibility.hapticsEnabled)),
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
