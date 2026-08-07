import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;

import '../../saves/hub_save_profile_manager.dart';
import '../../saves/save_profile.dart';

class HubSaveProfilesScreen extends StatefulWidget {
  const HubSaveProfilesScreen({
    super.key,
    required this.manager,
    required this.initialSelection,
    required this.onSelected,
    required this.onClose,
    this.initialProfiles,
  });

  final HubSaveProfilesController manager;
  final HubSaveSelection initialSelection;
  final ValueChanged<HubSaveSelection> onSelected;
  final VoidCallback onClose;
  final List<HubManagedSaveProfile>? initialProfiles;

  @override
  State<HubSaveProfilesScreen> createState() => _HubSaveProfilesScreenState();
}

class _HubSaveProfilesScreenState extends State<HubSaveProfilesScreen> {
  List<HubManagedSaveProfile>? _profiles;
  String? _profileId;
  String? _busyError;

  @override
  void initState() {
    super.initState();
    _profileId = widget.initialSelection.profileId;
    _profiles = widget.initialProfiles;
    if (_profiles == null) unawaited(_reload());
  }

  Future<void> _reload() async {
    try {
      final profiles = await widget.manager.load();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        if (!profiles.any((entry) => entry.profile.profileId == _profileId)) {
          _profileId = profiles.firstOrNull?.profile.profileId;
        }
        _busyError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _profiles = const <HubManagedSaveProfile>[];
          _profileId = null;
          _busyError = HubSaveProfilesStrings.of(context).loadFailed;
        });
      }
    }
  }

  HubManagedSaveProfile? get _selectedProfile {
    final profiles = _profiles;
    if (profiles == null) return null;
    return profiles
        .where((entry) => entry.profile.profileId == _profileId)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final strings = HubSaveProfilesStrings.of(context);
    final profiles = _profiles;
    return Scaffold(
      body: player_ui.PlayerSurface(
        maxWidth: 920,
        child: profiles == null
            ? Center(
                child: player_ui.PlayerLoadingSurface(
                  stage: strings.title,
                ),
              )
            : SingleChildScrollView(
                child: player_ui.PlayerPanel(
                  elevated: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              strings.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey<String>(
                              'save-profiles-close',
                            ),
                            tooltip: strings.close,
                            onPressed: widget.onClose,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: player_ui.PlayerSpacing.md),
                      if (_busyError case final error?) ...<Widget>[
                        Text(error, textAlign: TextAlign.center),
                        const SizedBox(height: player_ui.PlayerSpacing.sm),
                      ],
                      DropdownButtonFormField<String>(
                        key: const ValueKey<String>('save-profile-picker'),
                        isExpanded: true,
                        initialValue: _profileId,
                        decoration: InputDecoration(
                          labelText: strings.profile,
                        ),
                        items: profiles
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.profile.profileId,
                                child: Text(entry.profile.displayName),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            setState(() => _profileId = value),
                      ),
                      const SizedBox(height: player_ui.PlayerSpacing.sm),
                      Wrap(
                        spacing: player_ui.PlayerSpacing.xs,
                        runSpacing: player_ui.PlayerSpacing.xs,
                        children: <Widget>[
                          FilledButton.icon(
                            key: const ValueKey<String>(
                              'save-profile-create',
                            ),
                            onPressed: _createProfile,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: Text(strings.createProfile),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey<String>(
                              'save-profile-rename',
                            ),
                            onPressed: _selectedProfile == null
                                ? null
                                : _renameProfile,
                            icon: const Icon(Icons.edit),
                            label: Text(strings.rename),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey<String>(
                              'save-profile-delete',
                            ),
                            onPressed: _selectedProfile == null
                                ? null
                                : _deleteProfile,
                            icon: const Icon(Icons.delete_outline),
                            label: Text(strings.delete),
                          ),
                        ],
                      ),
                      const SizedBox(height: player_ui.PlayerSpacing.lg),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              strings.slots,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton.filledTonal(
                            key: const ValueKey<String>('save-slot-create'),
                            tooltip: strings.createSlot,
                            onPressed:
                                _selectedProfile == null ? null : _createSlot,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: player_ui.PlayerSpacing.sm),
                      if (_selectedProfile == null ||
                          _selectedProfile!.slots.isEmpty)
                        player_ui.PlayerEmptyState(
                          icon: Icons.save_outlined,
                          title: strings.noSlot,
                          message: strings.createFirstSlot,
                        )
                      else
                        for (final slot in _selectedProfile!.slots)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: player_ui.PlayerSpacing.sm,
                            ),
                            child: player_ui.PlayerPanel(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          slot.metadata.displayName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(_slotSubtitle(strings, slot)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: ValueKey<String>(
                                      'save-slot-delete-'
                                      '${slot.metadata.slotId}',
                                    ),
                                    tooltip: strings.delete,
                                    onPressed: () => _deleteSlot(slot),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  FilledButton(
                                    key: ValueKey<String>(
                                      'save-slot-select-'
                                      '${slot.metadata.slotId}',
                                    ),
                                    onPressed: () => widget.onSelected(
                                      HubSaveSelection(
                                        profileId:
                                            _selectedProfile!.profile.profileId,
                                        slotId: slot.metadata.slotId,
                                      ),
                                    ),
                                    child: Text(strings.select),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _slotSubtitle(
    HubSaveProfilesStrings strings,
    HubManagedSaveSlot slot,
  ) {
    final summary = slot.summary;
    if (summary == null || summary.updatedAt == null) return strings.emptySlot;
    final local = summary.updatedAt!.toLocal();
    return '${strings.lastUsed} '
        '${local.toIso8601String().replaceFirst('T', ' ').substring(0, 16)} '
        '· ${summary.playTimeSeconds ?? 0}s';
  }

  Future<void> _createProfile() async {
    final name = await _askName(
      title: HubSaveProfilesStrings.of(context).createProfile,
      initialValue: '',
    );
    if (name == null) return;
    final profile = await widget.manager.createProfile(name);
    _profileId = profile.profileId;
    await _reload();
  }

  Future<void> _renameProfile() async {
    final selected = _selectedProfile!;
    final name = await _askName(
      title: HubSaveProfilesStrings.of(context).rename,
      initialValue: selected.profile.displayName,
    );
    if (name == null) return;
    await widget.manager.renameProfile(selected.profile, name);
    await _reload();
  }

  Future<void> _deleteProfile() async {
    final selected = _selectedProfile!;
    final confirmed = await _confirmDelete(
      HubSaveProfilesStrings.of(context).deleteProfile(selected.profile),
    );
    if (!confirmed) return;
    await widget.manager.deleteProfile(selected.profile.profileId);
    await _reload();
  }

  Future<void> _createSlot() async {
    final name = await _askName(
      title: HubSaveProfilesStrings.of(context).createSlot,
      initialValue: '',
    );
    if (name == null) return;
    await widget.manager.createSlot(
      profileId: _selectedProfile!.profile.profileId,
      displayName: name,
    );
    await _reload();
  }

  Future<void> _deleteSlot(HubManagedSaveSlot slot) async {
    final confirmed = await _confirmDelete(
      HubSaveProfilesStrings.of(context).deleteSlot(slot.metadata.displayName),
    );
    if (!confirmed) return;
    await widget.manager.deleteSlot(
      profileId: _selectedProfile!.profile.profileId,
      slotId: slot.metadata.slotId,
    );
    await _reload();
  }

  Future<String?> _askName({
    required String title,
    required String initialValue,
  }) async {
    final strings = HubSaveProfilesStrings.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => _SaveNameDialog(
        title: title,
        initialValue: initialValue,
        strings: strings,
      ),
    );
  }

  Future<bool> _confirmDelete(String message) async {
    final strings = HubSaveProfilesStrings.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.confirmDeletion),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                key: const ValueKey<String>('save-delete-confirm'),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(strings.delete),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _SaveNameDialog extends StatefulWidget {
  const _SaveNameDialog({
    required this.title,
    required this.initialValue,
    required this.strings,
  });

  final String title;
  final String initialValue;
  final HubSaveProfilesStrings strings;

  @override
  State<_SaveNameDialog> createState() => _SaveNameDialogState();
}

class _SaveNameDialogState extends State<_SaveNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: TextField(
          key: const ValueKey<String>('save-name-field'),
          controller: _controller,
          autofocus: true,
          maxLength: 80,
          decoration: InputDecoration(labelText: widget.strings.name),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            key: const ValueKey<String>('save-name-confirm'),
            onPressed: () {
              final value = _controller.text.trim();
              if (value.isNotEmpty) Navigator.of(context).pop(value);
            },
            child: Text(widget.strings.confirm),
          ),
        ],
      );
}

final class HubSaveProfilesStrings {
  const HubSaveProfilesStrings(this.fr);

  factory HubSaveProfilesStrings.of(BuildContext context) =>
      HubSaveProfilesStrings(
        Localizations.localeOf(context).languageCode == 'fr',
      );

  final bool fr;

  String get title => fr ? 'Profils et sauvegardes' : 'Profiles and saves';
  String get open => fr ? 'Profils' : 'Profiles';
  String get close => fr ? 'Fermer' : 'Close';
  String get profile => fr ? 'Profil' : 'Profile';
  String get slots => fr ? 'Slots' : 'Slots';
  String get createProfile => fr ? 'Nouveau profil' : 'New profile';
  String get createSlot => fr ? 'Nouveau slot' : 'New slot';
  String get rename => fr ? 'Renommer' : 'Rename';
  String get delete => fr ? 'Supprimer' : 'Delete';
  String get select => fr ? 'Sélectionner' : 'Select';
  String get noSlot => fr ? 'Aucun slot' : 'No slot';
  String get createFirstSlot =>
      fr ? 'Créez un slot pour commencer.' : 'Create a slot to begin.';
  String get emptySlot => fr ? 'Slot vide' : 'Empty slot';
  String get lastUsed => fr ? 'Dernière utilisation :' : 'Last used:';
  String get loadFailed =>
      fr ? 'Impossible de charger les profils.' : 'Could not load profiles.';
  String get name => fr ? 'Nom affiché' : 'Display name';
  String get cancel => fr ? 'Annuler' : 'Cancel';
  String get confirm => fr ? 'Valider' : 'Confirm';
  String get confirmDeletion =>
      fr ? 'Confirmer la suppression' : 'Confirm deletion';

  String deleteProfile(SaveProfile profile) => fr
      ? 'Supprimer le profil « ${profile.displayName} » et tous ses slots ?'
      : 'Delete profile “${profile.displayName}” and all of its slots?';

  String deleteSlot(String name) => fr
      ? 'Supprimer définitivement le slot « $name » ?'
      : 'Permanently delete slot “$name”?';
}
