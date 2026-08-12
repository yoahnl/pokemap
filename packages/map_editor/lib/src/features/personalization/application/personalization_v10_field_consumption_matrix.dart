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

  void requireCompleteFor(Set<String> fieldGroups) {
    final uncovered =
        fieldGroups
            .where(
              (path) =>
                  !excludedFieldReasons.containsKey(path) &&
                  !entries.any((entry) => entry.covers(path)),
            )
            .toList(growable: false)
          ..sort();
    if (uncovered.isNotEmpty) {
      throw StateError(
        'Presentation V$schemaVersion fields without control, preview, '
        'runtime, export and MCP evidence: $uncovered.',
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
          fieldGroups: const <String>{'/presentation/typography'},
          previewWidget: 'PlayerTitleSurface',
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
            '/presentation/dialogue',
            '/presentation/layouts/dialogue',
          },
          previewWidget: 'PlayerDialogueSurface',
        ),
        _entry(
          capabilityId: 'battle.hud',
          fieldGroups: const <String>{'/presentation/battle'},
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
