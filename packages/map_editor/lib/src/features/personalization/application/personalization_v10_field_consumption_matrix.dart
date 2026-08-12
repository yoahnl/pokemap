import 'personalization_capability_registry.dart';

const projectPresentationV10AuthorableFieldGroups = <String>{
  '/presentation/branding',
  '/presentation/title',
  '/presentation/intro',
  '/presentation/titleMotion',
  '/presentation/typography',
  '/presentation/theme',
  '/presentation/surfacePalettes',
  '/presentation/pause',
  '/presentation/dialogue',
  '/presentation/battle',
  '/presentation/menuLabels',
  '/presentation/windows',
  '/presentation/layouts/title',
  '/presentation/layouts/pauseMenu',
  '/presentation/layouts/dialogue',
  '/presentation/layouts/battle',
};

final class PersonalizationFieldConsumptionEntry {
  PersonalizationFieldConsumptionEntry({
    required Iterable<String> fieldGroups,
    required this.capabilityId,
    required this.editorControlKey,
    required this.previewWidget,
    required this.runtimeConsumer,
    this.exportConsumer = 'GamePackageBuilder',
    this.mcpAction = 'presentation.update',
  }) : fieldGroups = Set.unmodifiable(fieldGroups) {
    if (this.fieldGroups.isEmpty ||
        this.fieldGroups.any(
          (path) => !path.startsWith('/presentation/') || path.endsWith('/'),
        )) {
      throw ArgumentError.value(fieldGroups, 'fieldGroups');
    }
    if (<String>[
      capabilityId,
      editorControlKey,
      previewWidget,
      runtimeConsumer,
      exportConsumer,
      mcpAction,
    ].any((value) => value.trim().isEmpty)) {
      throw ArgumentError('Field consumption evidence must not be blank.');
    }
  }

  final Set<String> fieldGroups;
  final String capabilityId;
  final String editorControlKey;
  final String previewWidget;
  final String runtimeConsumer;
  final String exportConsumer;
  final String mcpAction;

  bool covers(String path) => fieldGroups.any(
    (fieldGroup) => path == fieldGroup || path.startsWith('$fieldGroup/'),
  );
}

final class PersonalizationFieldConsumptionMatrix {
  PersonalizationFieldConsumptionMatrix({
    required this.schemaVersion,
    required Iterable<PersonalizationFieldConsumptionEntry> entries,
    required Map<String, String> excludedFieldReasons,
  }) : entries = List.unmodifiable(entries),
       excludedFieldReasons = Map.unmodifiable(excludedFieldReasons) {
    if (schemaVersion <= 0 || this.entries.isEmpty) {
      throw ArgumentError('The field consumption matrix must not be empty.');
    }
    if (this.excludedFieldReasons.entries.any(
      (entry) =>
          !entry.key.startsWith('/presentation/') || entry.value.trim().isEmpty,
    )) {
      throw ArgumentError.value(excludedFieldReasons, 'excludedFieldReasons');
    }
    final owners = <String, String>{};
    for (final entry in this.entries) {
      for (final fieldGroup in entry.fieldGroups) {
        final previous = owners[fieldGroup];
        if (previous != null) {
          throw ArgumentError(
            'Presentation field group $fieldGroup is owned by both '
            '$previous and ${entry.capabilityId}.',
          );
        }
        owners[fieldGroup] = entry.capabilityId;
      }
    }
  }

  final int schemaVersion;
  final List<PersonalizationFieldConsumptionEntry> entries;
  final Map<String, String> excludedFieldReasons;

  void requireDeclaredGroups(Set<String> fieldGroups) {
    final undeclared =
        fieldGroups
            .where(
              (path) => !entries.any(
                (entry) => entry.fieldGroups.any(
                  (fieldGroup) =>
                      fieldGroup == path || fieldGroup.startsWith('$path/'),
                ),
              ),
            )
            .toList(growable: false)
          ..sort();
    if (undeclared.isNotEmpty) {
      throw StateError(
        'Presentation V$schemaVersion authorable groups without declared '
        'evidence: $undeclared.',
      );
    }
  }

  void requireCompleteFor(Set<String> fieldGroups) {
    final uncovered = <String>[];
    final ambiguous = <String>[];
    for (final path in fieldGroups) {
      if (excludedFieldReasons.containsKey(path)) continue;
      final owners = entries.where((entry) => entry.covers(path)).length;
      if (owners == 0) uncovered.add(path);
      if (owners > 1) ambiguous.add(path);
    }
    uncovered.sort();
    ambiguous.sort();
    if (uncovered.isNotEmpty || ambiguous.isNotEmpty) {
      throw StateError(
        'Presentation V$schemaVersion fields without control, preview, '
        'runtime, export and MCP evidence: $uncovered; fields with competing '
        'owners: $ambiguous.',
      );
    }
  }
}

final personalizationV10FieldConsumptionMatrix =
    PersonalizationFieldConsumptionMatrix(
      schemaVersion: 10,
      excludedFieldReasons: const <String, String>{
        '/presentation/schemaVersion':
            'Version discriminator maintained by the codec.',
      },
      entries: <PersonalizationFieldConsumptionEntry>[
        _entry(
          capabilityId: 'title.media',
          fieldGroups: const <String>{'/presentation/branding'},
          previewWidget: 'PlayerTitleSurface',
        ),
        _entry(
          capabilityId: 'title.presentation',
          fieldGroups: const <String>{
            '/presentation/title',
            '/presentation/layouts/title',
          },
          previewWidget: 'PlayerTitleSurface',
        ),
        _entry(
          capabilityId: 'intro.media',
          fieldGroups: const <String>{'/presentation/intro'},
          previewWidget: 'PlayerIntroVideoSurface',
        ),
        _entry(
          capabilityId: 'title.motion',
          fieldGroups: const <String>{'/presentation/titleMotion'},
          previewWidget: 'PlayerTitleSurface',
        ),
        _entry(
          capabilityId: 'global.typography',
          fieldGroups: const <String>{
            '/presentation/typography/display',
            '/presentation/typography/body',
          },
          previewWidget: 'PlayerTitleSurface',
        ),
        _entry(
          capabilityId: 'dialogue.typography',
          fieldGroups: const <String>{'/presentation/typography/dialogue'},
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'battle.typography',
          fieldGroups: const <String>{
            '/presentation/typography/numbers',
            '/presentation/typography/combat',
          },
          previewWidget: 'PlayerBattleScene',
        ),
        _entry(
          capabilityId: 'global.colors',
          fieldGroups: const <String>{
            '/presentation/theme',
            '/presentation/surfacePalettes',
          },
          previewWidget: 'PlayerTitleSurface',
        ),
        _entry(
          capabilityId: 'pause.actions',
          fieldGroups: const <String>{
            '/presentation/pause',
            '/presentation/menuLabels',
          },
          previewWidget: 'RuntimePlayerPauseShell',
        ),
        _entry(
          capabilityId: 'global.windows',
          fieldGroups: const <String>{'/presentation/windows'},
          previewWidget: 'RuntimePlayerPauseShell',
        ),
        _entry(
          capabilityId: 'pause.layout',
          fieldGroups: const <String>{'/presentation/layouts/pauseMenu'},
          previewWidget: 'RuntimePlayerPauseShell',
        ),
        _entry(
          capabilityId: 'dialogue.geometry',
          fieldGroups: const <String>{
            '/presentation/dialogue/placement',
            '/presentation/dialogue/shape',
            '/presentation/dialogue/cornerRadius',
            '/presentation/dialogue/borderWidth',
            '/presentation/dialogue/contentPadding',
            '/presentation/dialogue/margin',
            '/presentation/dialogue/maxWidthFactor',
            '/presentation/layouts/dialogue',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'dialogue.colors',
          fieldGroups: const <String>{
            '/presentation/dialogue/surfaceColor',
            '/presentation/dialogue/borderColor',
            '/presentation/dialogue/textColor',
            '/presentation/dialogue/fillOpacity',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'dialogue.portrait',
          fieldGroups: const <String>{
            '/presentation/dialogue/portraitSide',
            '/presentation/dialogue/portraitSize',
            '/presentation/dialogue/portraitFrameWidth',
            '/presentation/dialogue/portraitFrameColor',
            '/presentation/dialogue/portraitShape',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'dialogue.nameplate',
          fieldGroups: const <String>{
            '/presentation/dialogue/nameplateStyle',
            '/presentation/dialogue/nameplateBorderWidth',
            '/presentation/dialogue/nameplateSurfaceColor',
            '/presentation/dialogue/nameplateBorderColor',
            '/presentation/dialogue/nameplateTextColor',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'dialogue.choices',
          fieldGroups: const <String>{
            '/presentation/dialogue/choiceShape',
            '/presentation/dialogue/choiceSpacing',
            '/presentation/dialogue/choiceSelectedColor',
            '/presentation/dialogue/choiceDisabledOpacity',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'dialogue.progress',
          fieldGroups: const <String>{
            '/presentation/dialogue/progressIndicator',
            '/presentation/dialogue/progressIndicatorColor',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'dialogue.motion',
          fieldGroups: const <String>{
            '/presentation/dialogue/portraitTransition',
            '/presentation/dialogue/portraitTransitionMilliseconds',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'battle.commands',
          fieldGroups: const <String>{
            '/presentation/battle/commands',
            '/presentation/battle/commandLayout',
            '/presentation/battle/commandColumns',
            '/presentation/battle/commandPadding',
            '/presentation/battle/commandSurfaceColor',
            '/presentation/battle/commandBorderColor',
            '/presentation/battle/commandTextColor',
            '/presentation/battle/commandSelectionColor',
            '/presentation/battle/showCommandIcons',
            '/presentation/battle/commandShape',
          },
          previewWidget: 'PlayerBattleScene',
        ),
        _entry(
          capabilityId: 'battle.hud',
          fieldGroups: const <String>{
            '/presentation/battle/playerHudPosition',
            '/presentation/battle/enemyHudPosition',
            '/presentation/battle/hudShape',
            '/presentation/battle/hpBarShape',
            '/presentation/battle/hpHealthyColor',
            '/presentation/battle/hpWarningColor',
            '/presentation/battle/hpDangerColor',
            '/presentation/battle/statusColor',
            '/presentation/battle/showLevel',
            '/presentation/battle/showExactHp',
            '/presentation/battle/showOwnerLabel',
          },
          previewWidget: 'PlayerBattleScene',
        ),
        _entry(
          capabilityId: 'battle.moves',
          fieldGroups: const <String>{'/presentation/battle/moves'},
          previewWidget: 'PlayerBattleScene',
        ),
        _entry(
          capabilityId: 'battle.target',
          fieldGroups: const <String>{'/presentation/battle/target'},
          previewWidget: 'PlayerBattleScene',
        ),
        _entry(
          capabilityId: 'battle.message',
          fieldGroups: const <String>{'/presentation/battle/message'},
          previewWidget: 'PlayerBattleScene',
        ),
        _entry(
          capabilityId: 'battle.layout',
          fieldGroups: const <String>{'/presentation/layouts/battle'},
          previewWidget: 'PlayerBattleScene',
        ),
      ],
    );

PersonalizationFieldConsumptionEntry _entry({
  required String capabilityId,
  required Set<String> fieldGroups,
  required String previewWidget,
}) {
  final capability = personalizationCapabilityRegistry.require(capabilityId);
  return PersonalizationFieldConsumptionEntry(
    fieldGroups: fieldGroups,
    capabilityId: capability.id,
    editorControlKey: capability.testKey!,
    previewWidget: previewWidget,
    runtimeConsumer: capability.runtimeSurface!,
  );
}
