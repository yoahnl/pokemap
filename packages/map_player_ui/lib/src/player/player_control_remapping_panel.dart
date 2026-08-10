import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_control_profile.dart';
import 'player_control_strings.dart';

class PlayerControlRemappingPanel extends StatelessWidget {
  const PlayerControlRemappingPanel({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final PlayerControlProfile profile;
  final ValueChanged<PlayerControlProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = PlayerControlStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(strings.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: PlayerSpacing.sm),
        for (final device in PlayerControlDevice.values) ...<Widget>[
          _DeviceBindings(
            device: device,
            profile: profile,
            strings: strings,
            onChanged: onChanged,
          ),
          const SizedBox(height: PlayerSpacing.sm),
        ],
      ],
    );
  }
}

class _DeviceBindings extends StatelessWidget {
  const _DeviceBindings({
    required this.device,
    required this.profile,
    required this.strings,
    required this.onChanged,
  });

  final PlayerControlDevice device;
  final PlayerControlProfile profile;
  final PlayerControlStrings strings;
  final ValueChanged<PlayerControlProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    final controls = device == PlayerControlDevice.touch
        ? const <RuntimeInputControl>[
            RuntimeInputControl.primary,
            RuntimeInputControl.secondary,
          ]
        : RuntimeInputControl.values;
    return PlayerPanel(
      surfaceRole: ProjectPresentationSurfaceRole.options,
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  strings.device(device),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: ValueKey<String>('controls-reset-${device.name}'),
                tooltip: strings.reset,
                onPressed: () => onChanged(profile.resetDevice(device)),
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          if (device == PlayerControlDevice.touch)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey<String>('controls-touch-swap'),
                onPressed: () => onChanged(
                  profile.swapBindings(
                    device: device,
                    first: RuntimeInputControl.primary,
                    second: RuntimeInputControl.secondary,
                  ),
                ),
                icon: const Icon(Icons.swap_horiz),
                label: Text(strings.swapTouch),
              ),
            ),
          for (final control in controls)
            Padding(
              padding: const EdgeInsets.only(top: PlayerSpacing.xs),
              child: DropdownButtonFormField<String>(
                key: ValueKey<String>(
                  'controls-${device.name}-${control.name}',
                ),
                initialValue: profile.bindingFor(device, control),
                decoration: InputDecoration(
                  labelText: strings.control(control),
                ),
                items: _inputs(device)
                    .map(
                      (inputId) => DropdownMenuItem<String>(
                        value: inputId,
                        child: Text(
                          PlayerControlProfile.glyphForInput(inputId),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (inputId) {
                  if (inputId == null) return;
                  final result = profile.rebind(
                    device: device,
                    control: control,
                    inputId: inputId,
                  );
                  if (result.hasConflict) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.conflict)),
                    );
                    return;
                  }
                  onChanged(result.profile);
                },
              ),
            ),
        ],
      ),
    );
  }

  Iterable<String> _inputs(PlayerControlDevice device) => switch (device) {
        PlayerControlDevice.keyboard => playerKeyboardInputs.keys,
        PlayerControlDevice.gamepad => playerGamepadInputs,
        PlayerControlDevice.touch => const <String>[
            'primaryButton',
            'secondaryButton',
          ],
      };
}
