import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';

@immutable
final class PlayerNewGameAvatarOption {
  const PlayerNewGameAvatarOption({
    required this.characterId,
    required this.label,
  });

  final String characterId;
  final String label;
}

@immutable
final class PlayerNewGameIdentityPresentation {
  PlayerNewGameIdentityPresentation({
    required String defaultName,
    this.defaultPronounSet = PlayerPronounSet.neutral,
    this.defaultAvatarCharacterId,
    List<PlayerNewGameAvatarOption> avatarOptions =
        const <PlayerNewGameAvatarOption>[],
  })  : defaultName = defaultName.trim(),
        avatarOptions =
            List<PlayerNewGameAvatarOption>.unmodifiable(avatarOptions) {
    if (this.defaultName.isEmpty) {
      throw ArgumentError.value(
          defaultName, 'defaultName', 'must not be empty');
    }
  }

  final String defaultName;
  final PlayerPronounSet defaultPronounSet;
  final String? defaultAvatarCharacterId;
  final List<PlayerNewGameAvatarOption> avatarOptions;
}

class PlayerNewGameIdentityDialog extends StatefulWidget {
  const PlayerNewGameIdentityDialog({
    super.key,
    required this.presentation,
  });

  final PlayerNewGameIdentityPresentation presentation;

  @override
  State<PlayerNewGameIdentityDialog> createState() =>
      _PlayerNewGameIdentityDialogState();
}

class _PlayerNewGameIdentityDialogState
    extends State<PlayerNewGameIdentityDialog> {
  late final TextEditingController _nameController;
  late String? _avatarCharacterId;
  late PlayerPronounSet _pronounSet;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.presentation.defaultName,
    );
    _avatarCharacterId = _resolvedDefaultAvatar();
    _pronounSet = widget.presentation.defaultPronounSet;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _resolvedDefaultAvatar() {
    final options = widget.presentation.avatarOptions;
    final preferred = widget.presentation.defaultAvatarCharacterId;
    if (preferred != null &&
        options.any((option) => option.characterId == preferred)) {
      return preferred;
    }
    return options.firstOrNull?.characterId;
  }

  @override
  Widget build(BuildContext context) {
    final strings = PlayerIdentityStrings.of(context);
    return AlertDialog(
      key: const ValueKey<String>('player-new-game-identity-dialog'),
      title: Text(strings.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(strings.description),
              const SizedBox(height: PlayerSpacing.md),
              TextField(
                key: const ValueKey<String>('player-identity-name'),
                controller: _nameController,
                autofocus: true,
                maxLength: 24,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.name,
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              if (widget.presentation.avatarOptions.isNotEmpty) ...[
                const SizedBox(height: PlayerSpacing.sm),
                DropdownButtonFormField<String>(
                  key: const ValueKey<String>('player-identity-avatar'),
                  initialValue: _avatarCharacterId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: strings.avatar),
                  items: <DropdownMenuItem<String>>[
                    for (final option in widget.presentation.avatarOptions)
                      DropdownMenuItem<String>(
                        value: option.characterId,
                        child: Text(option.label),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _avatarCharacterId = value),
                ),
              ],
              const SizedBox(height: PlayerSpacing.sm),
              DropdownButtonFormField<PlayerPronounSet>(
                key: const ValueKey<String>('player-identity-pronouns'),
                initialValue: _pronounSet,
                isExpanded: true,
                decoration: InputDecoration(labelText: strings.pronouns),
                items: <DropdownMenuItem<PlayerPronounSet>>[
                  for (final set in PlayerPronounSet.values)
                    DropdownMenuItem<PlayerPronounSet>(
                      value: set,
                      child: Text(strings.pronounLabel(set)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _pronounSet = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('player-identity-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('player-identity-confirm'),
          onPressed: _confirm,
          child: Text(strings.start),
        ),
      ],
    );
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = PlayerIdentityStrings.of(context).nameError);
      return;
    }
    Navigator.of(context).pop(
      GameSessionPlayerIdentity(
        name: name,
        avatarCharacterId: _avatarCharacterId,
        pronounSet: _pronounSet,
      ),
    );
  }
}

final class PlayerIdentityStrings {
  const PlayerIdentityStrings._(this._isFrench);

  factory PlayerIdentityStrings.of(BuildContext context) =>
      PlayerIdentityStrings._(
        Localizations.localeOf(context).languageCode.toLowerCase() == 'fr',
      );

  final bool _isFrench;

  String get title => _isFrench ? 'Votre identité' : 'Your identity';
  String get description => _isFrench
      ? 'Personnalisez votre profil avant de commencer.'
      : 'Customize your profile before starting.';
  String get name => _isFrench ? 'Nom' : 'Name';
  String get avatar => _isFrench ? 'Avatar' : 'Avatar';
  String get pronouns => _isFrench ? 'Pronoms' : 'Pronouns';
  String get cancel => _isFrench ? 'Annuler' : 'Cancel';
  String get start => _isFrench ? 'Commencer' : 'Start';
  String get nameError => _isFrench ? 'Saisissez un nom.' : 'Enter a name.';

  String pronounLabel(PlayerPronounSet set) => switch (set) {
        PlayerPronounSet.neutral =>
          _isFrench ? 'Neutres — iel / ellui' : 'Neutral — they / them',
        PlayerPronounSet.feminine =>
          _isFrench ? 'Féminins — elle' : 'Feminine — she / her',
        PlayerPronounSet.masculine =>
          _isFrench ? 'Masculins — il / lui' : 'Masculine — he / him',
      };
}
